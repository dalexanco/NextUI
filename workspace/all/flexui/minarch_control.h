#ifndef FLEXUI_MINARCH_CONTROL_H
#define FLEXUI_MINARCH_CONTROL_H

// External control of a running game, for a pak or daemon that is not minarch.
//
//   SIGUSR1  save and quit, exactly like going to sleep then quitting from the
//            menu. A plain kill would lose the game's progress.
//   SIGUSR2  show the text left in MINARCH_NOTIFY_PATH as a toast over the
//            game, then delete the file.
//
// Without handlers both signals terminate minarch on the spot, so a sender
// must only use them against a minarch built with this seam.
//
// The handlers only raise a flag. The work runs once per frame on the main
// thread (MinarchControl_poll), because neither Menu_beforeSleep() nor
// Notification_push() is async-signal-safe.
//
// Header-only and included once, by minarch.c: minarch's makefile lists its
// sources one by one, and keeping the code here keeps that list untouched.
// A sender includes it without FLEXUI_MINARCH_CONTROL_IMPL, for the path only.

#define MINARCH_NOTIFY_PATH "/tmp/minarch_notify.txt"

#ifdef FLEXUI_MINARCH_CONTROL_IMPL

#include <signal.h>
#include <stdbool.h>
#include <unistd.h>

#include "api.h"
#include "utils.h"
#include "notification.h"
#include "../minarch/ma_menu.h"

extern int quit;
extern int show_menu;

static volatile sig_atomic_t minarch_stop_requested = 0;
static volatile sig_atomic_t minarch_notify_requested = 0;

static void MinarchControl_onSignal(int sig) {
	if (sig == SIGUSR1) minarch_stop_requested = 1;
	else if (sig == SIGUSR2) minarch_notify_requested = 1;
}

// Call once, after Notification_init().
static void MinarchControl_init(void) {
	signal(SIGUSR1, MinarchControl_onSignal);
	signal(SIGUSR2, MinarchControl_onSignal);
}

// Call once per frame from the main loop.
static void MinarchControl_poll(void) {
	if (minarch_notify_requested) {
		minarch_notify_requested = 0;
		if (exists(MINARCH_NOTIFY_PATH)) {
			char msg[NOTIFICATION_MAX_MESSAGE];
			getFile(MINARCH_NOTIFY_PATH, msg, sizeof(msg));
			unlink(MINARCH_NOTIFY_PATH);
			trimTrailingNewlines(msg);
			if (msg[0]) Notification_push(NOTIFICATION_SETTING, msg, NULL);
		}
	}

	if (minarch_stop_requested) {
		minarch_stop_requested = 0;
		LOG_info("stopping on SIGUSR1...\n");
		Menu_beforeSleep();
		show_menu = 0;
		quit = 1;
	}
}

#endif // FLEXUI_MINARCH_CONTROL_IMPL

#endif // FLEXUI_MINARCH_CONTROL_H
