/*===========================================================================*/
/* SEED reader     |              timedif                  |         utility */
/*===========================================================================*/
/*
	Name:		timedif
	Purpose:	compute difference between two times.
	Usage:		int timedif ();
				struct time time1;
				struct time time2;
				duration = timedif (time1, time2);
	Input:		time1 = the original time in struct time form (see Notes)
				time2 = the original time in struct time form (see Notes)
	Output:		dif = the time difference in fraction of seconds
	Externals:	none
	Warnings:	none
	Errors:		none
	Called by:	anything
	Calls to:	none
	Algorithm:	convert the input time, exclusive of year and day, to seconds;
				add increment number of seconds to time; convert result to
				hours, minutes, seconds, and fractional seconds, allowing for
				change of day and year.
	Notes:		The time structure looks like:
					struct time
					{
						int year;
						int day;
						int hour;
						int minute;
						int second;
						int fracsec;
					};
	Problems:	Gives incorrect result if there was a leap second at the year
				boundary
				Gives incorrect result if difference > 1 year
	References:	none
	Language:	C, hopefully ANSI standard
	Author:		Dennis O'Neill
	Revisions:	07/15/88  Dennis O'Neill  Initial preliminary release 0.9
				11/21/88  Dennis O'Neill  Production release 1.0
			07/13/92 Allen Nance returns double for spans gerater than 2.48 days
*/

#include "rdseed.h"

/* #define isaleap(year) (((year%100 != 0) && (year%4 == 0)) || (year%400 == 0)) */

#define TIME_PRECISION 10000

double timedif (time1, time2)
struct time time1;
struct time time2;
{
	double time1_sec, time2_sec, dif;
	int year;

	double d_dif;

	/* convert increment to hh:mm:ss.ffff */
	time1_sec  = time1.second;
	time1_sec += time1.minute  * 60;
	time1_sec += time1.hour    * 3600;
	time1_sec += (time1.day-1) * 3600 * 24;

	time2_sec  = time2.second;
	time2_sec += time2.minute  * 60;
	time2_sec += time2.hour    * 3600;
	time2_sec += (time2.day-1) * 3600 * 24;

	if (time1.year == time2.year)
	{
		dif = time2_sec - time1_sec;

		/* We want negative diffs, in output_sac */
		/* if (dif < 0) return(0); */

	}
	else 
		for (year = time1.year; year < time2.year; year++)
			dif += (isaleap(year) ? 366 : 365)*3600*24;

#if 0

	if (time2.year-time1.year == 1)
	{
		dif = (time2_sec-time1_sec);

		if (isaleap (time1.year))	
			dif += 366*3600*24;
		else 
			dif += 365*3600*24;
	}
	else 
		return(0);
#endif

	if (time2.fracsec >= time1.fracsec)
		d_dif = (double)dif*TIME_PRECISION + (double) (time2.fracsec-time1.fracsec);
	else
		d_dif = (double)(dif-1)*TIME_PRECISION + (double) ((time2.fracsec-time1.fracsec)+TIME_PRECISION);

#ifdef	DEBUG
	fprintf (stderr, "time2 = %04d.%03d,%02d:%02d:%02d.%04d time1 = %04d.%03d,%02d:%02d:%02d.%04d dif = %.4lf\n",
		 time2.year, time2.day, time2.hour, time2.minute, time2.second, time2.fracsec,
		 time1.year, time1.day, time1.hour, time1.minute, time1.second, time1.fracsec,
		 d_dif);
#endif
	return (d_dif);
}
