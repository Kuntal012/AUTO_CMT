
/*===========================================================================*/
/* SEED reader     |              log_errors			   |         utility */
/*===========================================================================*/
/*
 *	Name:		myfprintf, open_log_file, stderr_to_file, close_log_file	
 *	Purpose:	capture the program's stderr messages and duplicate the 
 *				output to a disk file.
 *	Usage:		void myfprintf(...); 
 *
 *	Input:		variable parameter list
 *	Output:		none
 *	Warnings:	none
 *	Errors:		none
 *	Called by:	anything
 *	Calls to:	none
 *	Algorithm:	none.
 *	Notes:		replaces fprintf by #defining fprintf as myfprintf, see
 *				rdseed.h
 *				This was done to redirect fprintf(stderr,...) to a file.
 *				If no stderr processing, then send to fprintf().
 *	Problems:	None
 *	Language:	C, hopefully ANSI standard
 *	Author:		Chris Laughbon	
 *	Revisions:	
 * 
 */

/* ---------------------------- Includes -------------------------------- */

#include <stdio.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/param.h>
#include <pwd.h>
#include <time.h>



/* ---------------------------- Defines --------------------------------- */
#define ERR_FILE_EXT	".stderr.msg"
#define ERR_FILE_NAME	"rdseed.err_log"
#define RDSEED_ALERT_FNAME "rdseed.alert_log"
#define TRUE 1
#define FALSE 0
#define BOOL int

/* ---------------------------- Global Variables ------------------------ */

int rdseed_alert = 0;

/* ---------------------------- Local Variables ------------------------- */
static BOOL error_log_inited = FALSE;
static char input_fname[MAXPATHLEN];

/* ----------------------------- External Variables --------------------- */

extern char Rdseed_Cwd[];

/* ---------------------------------------------------------------------- */


void stderr_to_file();


void myfprintf(FILE *fp, char *fmt, ...)
{
	va_list args;

	va_start(args,fmt);

	vfprintf(fp, fmt, args);

	fflush(fp);

	/* if output to stderr, then add to log file */

	/*if (error_log_inited && fp == stderr)
		stderr_to_file(fmt, ap);*/

	va_end(args);

	return;

}

void save_myfprintf(FILE *fp, ...)
{
	va_list ap;
	char *fmt;

/*	char *fmt; */

	va_start(ap,fp);

/*	fp = va_arg(ap, FILE *); */

	fmt = va_arg(ap, char *);

	vfprintf(fp, fmt, ap);

	fflush(fp);

	/* if output to stderr, then add to log file */

	if (error_log_inited && fp == stderr)
		stderr_to_file(fmt, ap);

	va_end(ap);

	return;

}

/* ----------------------------------------------------------------------- */

void stderr_to_file(fmt, ap)
char *fmt;
char *ap;


{
	FILE *fptr;
	
	char now_dir[MAXPATHLEN];

	getcwd(now_dir, MAXPATHLEN);

	if (strcmp(now_dir, Rdseed_Cwd))
		chdir(Rdseed_Cwd);

	fptr = fopen(input_fname, "a");
 
	vfprintf(fptr, fmt, ap);

	fclose(fptr);

	if (strcmp(now_dir, Rdseed_Cwd)) 
                chdir(now_dir);

	return;

}

/* ----------------------------------------------------------------------- */
void init_error_file()

{

	/* check to make sure file is writable.
	 * If not, then write to /tmp. Still problems?, then
	 * continue but no error logging.
	 */

	struct timeval tp;
    	struct timezone tz;
	struct tm *tm;
	char buf[200];

	gettimeofday(&tp, &tz);
	tm = localtime((const time_t *)&(tp.tv_sec));
	strftime(buf, sizeof(buf), "%m.%d.%y", tm);
	
	sprintf(input_fname, "%s.%s", ERR_FILE_NAME, buf);

	if (!is_writable("."))
	{
		fprintf(stderr, "WARNING: Unable to write to current directory for the error message file!\n");

		fprintf(stderr, "Using /tmp directory instead.\n");
	
		if (!is_writable("/tmp")) 
		{
			fprintf(stderr, "WARNING: Unable to write to /tmp for the error message file!\n");
 
        	fprintf(stderr, "Error file processing is cancelled for this run.\n");
			return;
		}

	}

	if (!add_header())
	{
		fprintf(stderr, "WARNING: Unable to write header to the error message file!\n");
  
            fprintf(stderr, "Error file processing is cancelled for this run.\n");
            return;

	}

	/* Got this far...alls well */
	error_log_inited = TRUE;
	
}


/* ------------------------------------------------------------------------ */

BOOL is_writable(fname)
char *fname;

{
	struct stat s;
                
    if (stat(fname, &s) == -1)
		return FALSE; 
	
    return (s.st_mode & S_IWUSR);

}

/* ------------------------------------------------------------------------ */
BOOL add_header()

{
	/* create opening line with run start time and date */

	FILE *fptr;

	struct timeval tp; 
	struct timezone tz; 
 
   	struct passwd *pw_ent; 
 
   	gettimeofday(&tp, &tz);  
        
	pw_ent = getpwuid(getuid());
	
	fptr = fopen(input_fname, "a");

	if (fptr == (FILE *)NULL)
		return FALSE;

	fprintf(fptr, "\n==================================================\n");
	fprintf(fptr, "Error logging startup\nDate: %s\nBy: %s\n", ctime((const time_t *)&(tp.tv_sec)), pw_ent->pw_name);
 
	fclose(fptr);

	return(TRUE);
	
}

/* ------------------------------------------------------------------------ */
int rdseed_alert_msg_out(msg)
char *msg;

{
	FILE *fptr;

	char alert_fname[MAXPATHLEN];

        struct timeval tp;
        struct timezone tz;
        struct tm *tm;
        char buf[200];

	
        gettimeofday(&tp, &tz);
	tm = localtime((const time_t *)&(tp.tv_sec));
        strftime(buf, sizeof(buf), "%m.%d.%y", tm);

        sprintf(alert_fname, "%s.%s", RDSEED_ALERT_FNAME, buf);

	fptr = fopen(alert_fname, "a+");

	if (fptr == NULL)
	{
		fprintf(stderr, "Error - unable to open alert message file!\n");

		perror("rdseed:rdseed_alert_msg_out():");

		fprintf(stderr, "Alert message >>%s\n", msg);

		return 0;

	}


	if (fprintf(fptr, "%s\n", msg) == -1)
	{
		fprintf(stderr, "Error - unable to log alert message to file!\n");
                perror("rdseed:rdseed_alert_msg_out():"); 
 
                fprintf(stderr, "Alert message >>%s\n", msg);
 
                return 0; 

	}

	fclose(fptr);

	/* main() will look at this to remind the user to scan file, on exit */
	rdseed_alert = 1;

	return 1;

}

/* ------------------------------------------------------------------------ */


