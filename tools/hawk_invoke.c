/*
 * Copyright (c) 2011-2013 SUSE LLC, All Rights Reserved.
 * See COPYING for license.
 *
 * Author: Tim Serong <tserong@suse.com>
 *
 */

/*
 * hawk_invoke allows the hacluster user to run a small assortment of
 * Pacemaker CLI tools as another user, in order to support Pacemaker's
 * ACL feature.
 *
 * hawk_invoke:
 * - must be installed setuid root
 * - will refuse to run if invoked by anyone other than "root" or
 *   "hacluster"
 * - will only setuid() to a non-root user in the "haclient" group.
 * - will in turn only invoke a specific small set of Pacemaker
 *   CLI commands.
 *
 * The idea here is that hawk_invoke:
 * - Will allow "hacluster" or "root" to become a less-privileged
 *   user for the purposes of cluster administration.
 * - Will not allow the "hacluster" user to become a more-privileged
 *   user.
 * - The only exception here is for the execution of hb_report and
 *   "crm history", which must be run as "root", or they won't work.
 *   also adds an exception for "crm cluster copy ???/tmp/dashboard.js"
 * - Will not allow arbitrary commands to be executed as any other
 *   user.
 *
 * Usage:
 *
 *  /usr/sbin/hawk_invoke <username> <command> [args ...]
 *
 * Where:
 *
 *  username  = name of the user to run command as
 *  command   = short name of command (e.g.: "crm_mon")
 *  args      = any args for command
 *
 */

#define _GNU_SOURCE
#include <unistd.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <pwd.h>
#include <grp.h>
#include <errno.h>
#include <ctype.h>
#include "common.h"

struct cmd_map
{
	const char *name;	/* Short name of command */
	const char *path;	/* Full path to actual command */
};

static struct cmd_map commands[] = {
	{"cibadmin",       SBINDIR"/cibadmin"},
	{"crm",            SBINDIR"/crm"},
	{"crmadmin",       SBINDIR"/crmadmin"},
	{"crmd",           LIBDIR"/pacemaker/crmd"},
	{"crm_attribute",  SBINDIR"/crm_attribute"},
	{"crm_mon",        SBINDIR"/crm_mon"},
	{"crm_shadow",     SBINDIR"/crm_shadow"},
	{"crm_simulate",   SBINDIR"/crm_simulate"},
	{"pengine",        LIBDIR"/pacemaker/pengine"},
	{"hb_report",      SBINDIR"/hb_report"},
	{"booth",          SBINDIR"/booth"},
	{NULL, NULL}
};

#define DASHBOARD_FILE "/tmp/dashboard.js"


static void die(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	vfprintf(stderr, format, args);
	va_end(args);
	exit(1);
}

static int strendswith(char* str, char* tail)
{
	size_t l = strlen(str), t = strlen(tail);
	return l >= t && strncmp(str + l - t, tail, t) == 0;
}

static int valid_dashboard_file(char* str)
{
	char* s;
	for (s = str; *s; ++s) {
		if (*s == '.' && *(s + 1) == '.') {
			return 0;
		} else if (!isalnum(*s) && strchr(" :/_-.", *s) == NULL) {
			return 0;
		}
	}
	return strendswith(str, DASHBOARD_FILE);
}

/*
 * Allow chmod hacluster:haclient <path>/tmp/dashboard.js
 * and as little else as possible
 */
static int valid_run_command(char* str)
{
	#define TMPSTR_SIZE 512
	char tmp[TMPSTR_SIZE];
	size_t tmplen;
	memset(tmp, 0, TMPSTR_SIZE);
	snprintf(tmp, sizeof(tmp), "chown %s:%s ", HACLUSTER, HACLIENT);
	tmplen = strlen(tmp);
	if (strncmp(str, tmp, tmplen) != 0)
		return 0;
	return valid_dashboard_file(str + tmplen);
}

static int allow_root(int argc, char** argv)
{
	if (strcmp(argv[2], "hb_report") == 0)
		return 1;
	if (argc >= 4 &&
	    strcmp(argv[2], "crm") == 0 &&
	    strcmp(argv[3], "report") == 0)
		return 1;
	if (argc >= 4 &&
	    strcmp(argv[2], "crm") == 0 &&
	    strcmp(argv[3], "history") == 0)
		return 1;
	if (argc == 6 &&
	    strcmp(argv[2], "crm") == 0 &&
	    strcmp(argv[3], "cluster") == 0 &&
	    strcmp(argv[4], "copy") == 0 &&
	    valid_dashboard_file(argv[5]))
		return 1;
	if (argc == 6 &&
	    strcmp(argv[2], "crm") == 0 &&
	    strcmp(argv[3], "cluster") == 0 &&
	    strcmp(argv[4], "run") == 0 &&
	    valid_run_command(argv[5]))
		return 1;
	return 0;
}

int main(int argc, char **argv)
{
	uid_t uid;
	struct passwd *pwd;
	struct group *grp;
	char *grp_user;
	int i;
	int found = 0;
	struct cmd_map *cmd;
	char *home = NULL;
	char *cib_shadow = NULL;

	if (argc < 3) {
		die("Usage: %s <username> <command> [args ...]\n", argv[0]);
	}

	/* Ensure we're being run by either root or hacluster */
	uid = getuid();
	if (uid != 0) {
		/* Not root, let's see if we're running as hacluster */
		pwd = getpwuid(uid);

		#if WITHIN_VAGRANT == 1
		if (pwd == NULL || (strcmp(pwd->pw_name, HACLUSTER) != 0 && strcmp(pwd->pw_name, VAGRANT) != 0)) {
		#else
		if (pwd == NULL || strcmp(pwd->pw_name, HACLUSTER) != 0) {
		#endif
			/*
			 * Not hacluster either.
			 * TODO: log this to syslog, to alert sysadmin
			 * of potential nefarious local user.
			 */
			die("ERROR: Permission denied\n");
		}
	}

	/* See who we're trying to become... */
	pwd = getpwnam(argv[1]);
	if (pwd == NULL) {
		die("ERROR: User '%s' not found\n", argv[1]);
	}

	if ((pwd->pw_uid == 0 || strcmp(pwd->pw_name, "root") == 0) && allow_root(argc, argv)) {

		/*
		 * Special case to become root when running hb_report
		 * or "crm history", and we force group to HACLIENT.
		 */
		grp = getgrnam(HACLIENT);

	} else {

		/*
		 * Don't become root!
		 * (Is there really any sense checking for pw_name == "root"?
		 */
		if (pwd->pw_uid == 0 || strcmp(pwd->pw_name, "root") == 0) {
			die("ERROR: Thou shalt not become root\n");
		}

		/* Make sure the new user is in the haclient group */
		grp = getgrgid(pwd->pw_gid);
		if (grp == NULL || strcmp(grp->gr_name, HACLIENT) != 0) {
			/* Not the primary group, let's check the others */
			grp = getgrnam(HACLIENT);
			if (grp == NULL) {
				die("ERROR: Group '%s' does not exist\n", HACLIENT);
			}
			i = 0;
			found = 0;
			while ((grp_user = grp->gr_mem[i]) != NULL) {
				if (strcmp(grp_user, pwd->pw_name) == 0) {
					found = 1;
					break;
				}
				i++;
			}
			if (!found) {
				die("ERROR: User '%s' is not in the '%s' group\n", pwd->pw_name, HACLIENT);
			}
		}
	}

	/* Verify the command to execute is valid, and expand it */
	found = 0;
	for (cmd = commands; cmd->name != NULL; cmd++) {
		if (strcmp(cmd->name, argv[2]) == 0) {
			found = 1;
			break;
		}
	}
	if (!found) {
		die("ERROR: Invalid command '%s'\n", argv[2]);
	}
	/* (bit rough to drop const...) */
	argv[2] = (char *)cmd->path;

	/*
	 * Drop extraneous groups. Not doing this is a security issue.
	 * See POS36-C.
	 *
	 * This will fail if we aren't root, so don't bother checking
	 * the return value, this is just done as an optimistic privilege
	 * dropping function.
	 */
	{
		int save_errno = errno;
		setgroups(0, NULL);
		errno = save_errno;
	}

	/*
	 * Become the new user.  Note that at this point, grp still refers
	 * to the "haclient" group, either because that was the user's
	 * primary group, or because we looked that group up to search
	 * through its members.  Likewise pwd still refers to the user
	 * we're trying to become.
	 */
	if (setresgid(grp->gr_gid, grp->gr_gid, grp->gr_gid) != 0) {
		die("ERROR: Can't set group to '%s' (%d)\n", grp->gr_name, grp->gr_gid);
	}
	if (setresuid(pwd->pw_uid, pwd->pw_uid, pwd->pw_uid) != 0) {
		die("ERROR: Can't set user to '%s' (%d)\n", pwd->pw_name, pwd->pw_uid);
	}

	/*
	 * Bit of cleanup - is this in the right place, and is it really
	 * necessary?
	 */
	endpwent();
	endgrent();

	/* Clean up environment */
	home = getenv("HOME");
	if (home != NULL) {
		home = strdup(home);
	}
	cib_shadow = getenv("CIB_shadow");
	if (cib_shadow != NULL) {
		cib_shadow = strdup(cib_shadow);
	}
	if (clearenv() != 0) {
		die("ERROR: Can't clear environment");
	}
	setenv("PATH", SBINDIR":"BINDIR":/bin", 1);
	if (home != NULL) {
		setenv("HOME", home, 1);
	}
	if (cib_shadow != NULL) {
		setenv("CIB_shadow", cib_shadow, 1);
	}

	/* And away we go... */
	execv(argv[2], &argv[2]);
	perror(argv[2]);
	return 1;
}
