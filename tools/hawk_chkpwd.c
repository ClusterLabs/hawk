/*
 * hawk_chkpwd is almost identical to unix2_chkpwd, except:
 *  - argc must be 3 (i.e. must always specify PAM service
 *    and user to authenticate).
 *  - The user being authenticated must be in the "haclient"
 *    group.
 *  - There's no time penalty for failed authentication if
 *    invoked by the "hacluster" user.
 *
 * Blame for the above variation rests squarely with
 * Tim Serong <tserong@novell.com>.  Original header follows.
 *
 * Set*id helper program for PAM authentication.
 *
 * It is supposed to be called from pam_unix2's
 * pam_sm_authenticate function if the function notices
 * that it's unable to get the password from the shadow file
 * because it doesn't have sufficient permissions.
 *
 * Copyright (C) 2002 SuSE Linux AG
 *
 * Written by okir@suse.de, loosely based on unix_chkpwd
 * by Andrew Morgan.
 */

#include <security/pam_appl.h>
#include <security/_pam_macros.h>

#include <sys/types.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <unistd.h>
#include <pwd.h>
#include <grp.h>
#include <signal.h>
#include <fcntl.h>
#include <ctype.h>
#include "common.h"

enum {
	UNIX_PASSED = 0,
	UNIX_FAILED = 1
};

static char *	program_name;
static char	pass[64];
static int	npass = -1;

/*
 * Log error messages
 */
static void
_log_err(int err, const char *format,...)
{
	va_list args;

	va_start(args, format);
	openlog(program_name, LOG_CONS | LOG_PID, LOG_AUTH);
	vsyslog(err, format, args);
	va_end(args);
	closelog();
}

static void
su_sighandler(int sig)
{
	if (sig > 0) {
		/*
		 * Don't call non-reentrant functions in signal handler
		 * per bnc#665045 - dmesg will catch SEGV etc. anyway
		 */
		/* _log_err(LOG_NOTICE, "caught signal %d.", sig); */
		exit(sig);
	}
}

/*
 * Setup signal handlers
 */
static void
setup_signals(void)
{
	struct sigaction action;

	memset((void *) &action, 0, sizeof(action));
	action.sa_handler = su_sighandler;
	action.sa_flags = SA_RESETHAND;
	sigaction(SIGILL, &action, NULL);
	sigaction(SIGTRAP, &action, NULL);
	sigaction(SIGBUS, &action, NULL);
	sigaction(SIGSEGV, &action, NULL);
	action.sa_handler = SIG_IGN;
	action.sa_flags = 0;
	sigaction(SIGTERM, &action, NULL);
	sigaction(SIGHUP, &action, NULL);
	sigaction(SIGINT, &action, NULL);
	sigaction(SIGQUIT, &action, NULL);
	sigaction(SIGALRM, &action, NULL);
}

static int
_converse(int num_msg, const struct pam_message **msg,
		struct pam_response **resp, void *appdata_ptr)
{
	struct	pam_response *reply;
	int	num;

	if (!(reply = malloc(sizeof(*reply) * num_msg)))
		return PAM_CONV_ERR;

	for (num = 0; num < num_msg; num++) {
		reply[num].resp_retcode = PAM_SUCCESS;
		reply[num].resp = NULL;
		switch (msg[num]->msg_style) {
		case PAM_PROMPT_ECHO_ON:
			return PAM_CONV_ERR;
		case PAM_PROMPT_ECHO_OFF:
			/* read the password from stdin */
			if (npass < 0) {
				npass = read(STDIN_FILENO, pass, sizeof(pass)-1);
				if (npass < 0) {
					_log_err(LOG_DEBUG, "error reading password");
					return UNIX_FAILED;
				}
				pass[npass] = '\0';
			}
			reply[num].resp = strdup(pass);
			break;
		case PAM_TEXT_INFO:
		case PAM_ERROR_MSG:
			/* ignored */
			break;
		default:
			/* Must be an error of some sort... */
			return PAM_CONV_ERR;
		}
	}

	*resp = reply;
	return PAM_SUCCESS;
}

static int
_authenticate(const char *service, const char *user)
{
	struct pam_conv conv = { _converse, NULL };
	pam_handle_t	*pamh;
	int		err;

	err = pam_start(service, user, &conv, &pamh);
	if (err != PAM_SUCCESS) {
		_log_err(LOG_ERR, "pam_start(%s, %s) failed (errno %d)",
				service, user, err);
		return UNIX_FAILED;
	}

	err = pam_authenticate(pamh, 0);
	if (err != PAM_SUCCESS)
		_log_err(LOG_ERR, "pam_authenticate(%s, %s): %s",
				service, user,
				pam_strerror(pamh, err));

	if (err == PAM_SUCCESS)
	{
		int err2 = pam_setcred(pamh, PAM_REFRESH_CRED);
		if (err2 != PAM_SUCCESS)
			_log_err(LOG_ERR, "pam_setcred(%s, %s): %s",
					 service, user,
					 pam_strerror(pamh, err2));
		/*
		 * ignore errors on refresh credentials.
		 * If this did not work we use the old once.
		 */
	}

	pam_end(pamh, err);

	if (err != PAM_SUCCESS)
		return UNIX_FAILED;
	return UNIX_PASSED;
}

static char *
getuidname(uid_t uid)
{
	struct passwd *pw;
	static char username[32];

	pw = getpwuid(uid);
	if (pw == NULL)
		return NULL;

	strncpy(username, pw->pw_name, sizeof(username));
	username[sizeof(username) - 1] = '\0';

	endpwent();
	return username;
}

static int
in_haclient_grp(const char *user)
{
	int i = 0;
	char *grp_user = NULL;
	struct passwd *pwd = NULL;
	struct group *grp = NULL;

	pwd = getpwnam(user);
	if (pwd == NULL)
		return 0;

	grp = getgrgid(pwd->pw_gid);
	if (grp == NULL)
		return 0;

	if (strcmp(grp->gr_name, HACLIENT) == 0)
		return 1;

	grp = getgrnam(HACLIENT);
	if (grp == NULL)
		return 0;

	grp_user = grp->gr_mem[i];
	while (grp_user != NULL) {
		if (strcmp(user, grp_user) == 0)
			return 1;
		i++;
		grp_user = grp->gr_mem[i];
	}
	return 0;
}

static int
sane_pam_service(const char *name)
{
	const char *sp;
	char	path[128];

	if (strlen(name) > 32)
		return 0;
	for (sp = name; *sp; sp++) {
		if (!isalnum(*sp) && *sp != '_' && *sp != '-')
			return 0;
	}

	snprintf(path, sizeof(path), "/etc/pam.d/%s", name);
	return access(path, R_OK) == 0;
}

int
main(int argc, char *argv[])
{
	const char *program_name;
	char	*service, *user;
	int	fd;
	uid_t	uid;

	uid = getuid();

	/*
	 * Make sure standard file descriptors are connected.
	 */
	while ((fd = open("/dev/null", O_RDWR)) <= 2)
		;
	close(fd);

	/*
	 * Get the program name
	 */
	if (argc == 0)
		program_name = "hawk_chkpwd";
	else if ((program_name = strrchr(argv[0], '/')) != NULL)
		program_name++;
	else
		program_name = argv[0];

	/*
	 * Catch or ignore as many signal as possible.
	 */
	setup_signals();

	/*
	 * Check argument list
	 */
	if (argc != 3) {
		_log_err(LOG_NOTICE, "Bad number of arguments (%d)", argc);
		return UNIX_FAILED;
	}

	/*
	 * Get the service name and do some sanity checks on it
	 */
	service = argv[1];
	if (!sane_pam_service(service)) {
		_log_err(LOG_ERR, "Illegal service name '%s'", service);
		return UNIX_FAILED;
	}

	/*
	 * Discourage users messing around (fat chance)
	 */
	if (isatty(STDIN_FILENO) && uid != 0) {
		_log_err(LOG_NOTICE,
			"Inappropriate use of Unix helper binary [UID=%d]",
			 uid);
		fprintf(stderr,
			"This binary is not designed for running in this way\n"
			"-- the system administrator has been informed\n");
		sleep(10);	/* this should discourage/annoy the user */
		return UNIX_FAILED;
	}

	/*
	 * determine the caller's user name
	 */
	user = getuidname(uid);
	if (strcmp(user, argv[2])) {
		/* Discourage use of this program as a
		 * password cracker */
		if (uid != 0 && strcmp(user, HACLUSTER))
			sleep(5);
		user = argv[2];
	}
	if (!in_haclient_grp(user)) {
		_log_err(LOG_NOTICE,
			"Failed to authenticate user '%s' (not in group '%s')",
			user, HACLIENT);
		return UNIX_FAILED;
	}
	return _authenticate(service, user);
}
