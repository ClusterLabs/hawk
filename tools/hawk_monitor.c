/*
 * Copyright (c) 2010 Novell Inc., Tim Serong <tserong@novell.com>
 *                        All Rights Reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of version 2 of the GNU General Public License as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it would be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * Further, this software is distributed without any warranty that it is
 * free of the rightful claim of any third person regarding infringement
 * or the like.  Any license provided herein, whether implied or
 * otherwise, applies only to this software file.  Patent licenses, if
 * any, provided herein do not apply to combinations of this program with
 * other software, or any other product whatsoever.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write the Free Software Foundation,
 * Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
 */

/*
 * This monitor program is intentionally as dumb as a pile of rocks.
 * Its only purpose is to be polled by the user's web browser, to
 * indicate whether the state of the cluster has changed since the
 * status display was last rendered.  If something has changed, the
 * browser needs to make another proper request (to the Rails app)
 * to update the status display accordingly.
 *
 * USAGE:
 *
 * 1) Client invokes with QUERY_STRING == epoch (e.g.: /monitor?0:36:2),
 *    where epoch is either "admin_epoch:epoch:num_updates" from the CIB,
 *    or is an empty string (for unknown, or previously disconnected).
 *
 * 2) Server connects to CIB, and:
 *    - If client epoch is empty string:
 *      - If CIB connection succeeds, respond immediately with new epoch.
 *      - If connection fails, attept to connect for up to 60 seconds.
 *      - Finally, respond with either epoch = empty string (timeout) or
 *        real epoch from CIB if connection ultimately succeeded.
 *    - If client epoch is present:
 *      - If CIB connection fails, respond immediately with empty string.
 *      - If CIB connection succeeds, and CIB has a different epoch,
 *        respond immediately with the new epoch.
 *      - Otherwise, wait up to 60 seconds for something to change, then
 *        respond with either the new epoch (if something changed), the
 *        current epoch (if the timeout expired) or empty string (if the
 *        connection to CIB fell over).
 *
 * Note that the response from hawk_monitor will always be in the form:
 *
 *   Content-type: application/json
 *
 *   {"epoch":"n:n:n"}
 *
 * This means, from the client's perspective, the algorithm is:
 *
 * 1) Request https://SERVER:7630/monitor?EPOCH
 * 2) Wait and see what comes back.  If the epoch returned is in any
 *    way different to what you started with, fire off another request
 *    to update the display (https://SERVER:7630/main/status?format=json)
 * 3) Remember the new epoch, and go back to step 1.
 *
 * SECURITY/PERFORMANCE CONSIDERATIONS:
 *
 * - hawk_monitor runs as a regular CGI application, i.e. the web server forks
 *   a new process for each request.  This overhead is deemed acceptable, as
 *   this is for a low use monitoring app, not a heavy load public web site.
 *
 * - No authentication is performed, so anyone can get the current epoch from
 *   the CIB.  This data should not however constitute any sort of security
 *   risk.
 *
 * - It may be possible to perpetrate a DOS attack by invoking hundreds of
 *   instances of hawk_monitor in quick succession, because each instance
 *   potentially hangs around for 60 seconds).  Some consideration needs to
 *   be given to this, to find a balance between DOS risk as rendering the
 *   system unusable for multiple users, or multiple tabbed browsing sessions.
 */

#include <stdio.h>
#include <stdlib.h>

#include <crm/cib.h>
#include <crm/common/util.h>
#include <crm/common/mainloop.h>
/*
#include <crm/compatibility.h>

Don't have the above in SLES Pacemaker yet for some reason, so copy
a few choice bits...
*/

enum cib_errors {
	cib_ok		= pcmk_ok,
	cib_missing	= -EINVAL,
	cib_connection	= -ENOTCONN,
};

#define CONNECT_TIMEOUT		60
#define MAX_EPOCH_LENGTH	128	/* way longer than necessary */

int cib_connect(void);
void mon_cib_connection_destroy(gpointer user_data);
void crm_diff_update(const char *event, xmlNode *msg);
gboolean mon_timer_popped(gpointer data);
void mon_shutdown(int nsig);
void finish(void);
void get_new_epoch(void);

char *origin = NULL;

char new_epoch[MAX_EPOCH_LENGTH] = "";
cib_t *cib = NULL;
GMainLoop *mainloop = NULL;

/*
 * Based on cib_connect() crm_mon.c, but intentionally ignoring notify
 * callback setup errors (it's just not that important, we'll time
 * out anyway...)
 */
int cib_connect(void)
{
	int rc = cib_ok;
	CRM_CHECK(cib != NULL, return cib_missing);

	if (cib->state == cib_connected_query || cib->state == cib_connected_command)
		return cib_ok;

	rc = cib->cmds->signon(cib, crm_system_name, cib_query);

	if (rc != cib_ok)
		return rc;

	cib->cmds->set_connection_dnotify(cib, mon_cib_connection_destroy);
	cib->cmds->del_notify_callback(cib, T_CIB_DIFF_NOTIFY, crm_diff_update);
	cib->cmds->add_notify_callback(cib, T_CIB_DIFF_NOTIFY, crm_diff_update);

	return rc;
}

void mon_cib_connection_destroy(gpointer user_data)
{
	if (cib) {
		cib->cmds->signoff(cib);
		g_main_loop_quit(mainloop);
	}
}

void crm_diff_update(const char *event, xmlNode *msg)
{
	g_main_loop_quit(mainloop);
}

gboolean mon_timer_popped(gpointer data)
{
	g_main_loop_quit(mainloop);
	return FALSE;
}

void mon_shutdown(int nsig)
{
	finish();
}

void finish(void)
{
	if (cib != NULL) {
		get_new_epoch();	/* Last chance... */
		cib->cmds->signoff(cib);
		cib_delete(cib);
		cib = NULL;
	}
	printf("Content-type: application/json\n");
	if (origin) {
		printf("Access-Control-Allow-Origin: %s\n", origin);
		printf("Access-Control-Allow-Credentials: true\n");	/* may not be necessary */
	}
	printf("\n{\"epoch\":\"%s\"}", new_epoch);
	exit(0);
}

void get_new_epoch(void)
{
	int admin_epoch;
	int epoch;
	int num_updates;
	xmlNode *cib_top = NULL;
	cib->cmds->query(cib, "/cib", &cib_top, cib_sync_call|cib_scope_local|cib_xpath|cib_no_children);
	if (cib_version_details(cib_top, &admin_epoch, &epoch, &num_updates)) {
		snprintf(new_epoch, MAX_EPOCH_LENGTH, "%d:%d:%d", admin_epoch, epoch, num_updates);
	}
	free_xml(cib_top);
}

int main(int argc, char **argv)
{
	int rc = cib_ok;
	int timeout = 0;
	char *client_epoch = getenv("QUERY_STRING");
	if (client_epoch && client_epoch[0] == '\0')
		client_epoch = NULL;

	origin = getenv("HTTP_ORIGIN");

	/* Final arg appeared circa pcmk 1.1.8 */
	crm_log_init(NULL, LOG_CRIT, FALSE, FALSE, argc, argv, TRUE);

	cib = cib_new();

	rc = cib_connect();
	if (rc != cib_ok && client_epoch == NULL) {
		/* Client had no epoch, wait to connect */
		do {
			sleep(1);
			rc = cib_connect();
		} while (rc == cib_connection && ++timeout < CONNECT_TIMEOUT);
	}

	if (rc == cib_ok) {
		get_new_epoch();
		if (client_epoch != NULL && strcmp(client_epoch, new_epoch) == 0) {
			/* Wait a while to see if something changes */
			mainloop = g_main_loop_new(NULL, FALSE);
			mainloop_add_signal(SIGTERM, mon_shutdown);
			mainloop_add_signal(SIGINT, mon_shutdown);
			g_timeout_add(CONNECT_TIMEOUT * 1000, mon_timer_popped, NULL);
			g_main_loop_run(mainloop);
			g_main_loop_unref(mainloop);
		}
	}

	finish();
	return 0; /* never reached */
}

