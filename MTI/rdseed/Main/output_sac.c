/*===========================================================================*/
/* SEED reader     |              output_sac               |    subprocedure */
/*===========================================================================*/
/*
	Name:	output_sac
	Purpose:build and write a seismogram file from the SEED header tables
		and data files; serve as an example for users who wish to write
		their own "output_data" procedure.  This procedure writes SAC
		files.
	Usage:	void output_sac();

	Input:	none (gets its data from globally-available tables and files)
	Output:	none (writes a seismogram file; seismogram files are named by
		beginning time, station, and component; for example,
		1988.023.15.34.08.2800.ANMO.SPZ is the filename for a
		seismogram from year 1988, Julian day 23, 15:34:08.2800 UT,
		recorded at station ANMO from component SPZ.  Writes message
		to stderr describing the seismogram file being written.
	Externals:data_hdr - a table containing information about this seismogram
		current_station - a pointer to the SEED header tables for the
		station at which this seismogram was recorded
		current_channel - a pointer to the SEED header tables for the
		channel of the station at which this seismogram was recorded
	Warnings:unable to open seismogram file for writing
		failure to properly write the seismic data
	Errors:	none
	Called by:time_span_out
	Calls to:none
	Algorithm:build the seismogram file header by copying values from the
			structure "data_hdr" and the "current_station" and
			"current_channel" tables.  Write out the header and the data.
			This procedure may write either ASCII or binary data, depending
			upon the values of the variables "ascii" and "binary"; as
			implemented here, the programmer sets "ascii" to TRUE or FALSE
			and "binary" is automatically set to the negation of "ascii".
	Notes:	"output_data" is the name of the process called by
		"process_data" to write a seismogram file.  In the case shown
		here, the data are written in SAC format; the SAC format was
		chosen because many users have SAC available and will be able to
		use the output files directly.  If the user desires a different
		output format, this code and these notes should contain enough
		information for that user to construct his or her own 
		"output_data" procedure.

		The structure "data_hdr" contains the following information from
		the SEED fixed-length data header:

	structure element                     description
	====================================  ==========================
	struct input_data_hdr                 fixed data header
	{
		char station[5];                   station name
		char location[2];                  station location
		char channel[3];                   channel name
		char unused[2];                    not used
		struct input_time time;            time (see below)
		unsigned short int nsamples;       number samples
		short int sample_rate;             sample rate factor
		short int sample_rate_multiplier;  sample rate multiplier
		char activity_flags;               activity flags
		char io_flags;                     i/o flags
		char data_quality_flags;           data quality flags
		char number_blockettes;            # blockettes which follow
		long int number_time_corrections;  # .0001s time corrections
		unsigned short int bod;            beginning of data
		unsigned short int bofb;           beginning 1st blkt
	};
	struct input_time                     time from input stream
	{
		unsigned short int year;           year
		unsigned short int day;            Julian day
		char hour;                         hour
		char minute;                       minute
		char second;                       second
		char unused;
		unsigned short int fracsec;        10000ths of second
	};

	These header data are available to the programmer in the usual
	ways.  In the case shown here, a SAC header structure was
	defined in "sac.h" and various elements of the SAC header were
	filled in with data available from the SEED fixed-length data
	header.  See the section of code entitled "Build the SAC header"
	for examples.

	Other data are available from the tables pointed to by
	"current_station" and "current_channel".  These data are 
	described in Halbert et al. under the heading "Station Control
	Header Format".  The table structure is described in the leading
	comments to the main program ("rdseed.c") and in the 
	programmer's technical reference manual; the pointers
	"current_station" and "current_channel" are set by the procedure
	"process_data".  See the section of code within "Build the SAC 
	header" commented with "give values available from SEED tables 
	to SAC optional variables" for examples of the use of these
	station- and channel-specific items.

	Numeric data formats included here are correct for SAC.  The
	user may have to change them for output of data to be used by
	other seismic processing programs.
			
	Problems:	none known
	References:	Halbert, S. E., R. Buland, and C. R. Hutt (1988).  Standard for
			the Exchange of Earthquake Data (SEED), Version V2.0,
			February 25, 1988.  United States Geological Survey,
			Albuquerque Seismological Laboratory, Building 10002,
			Kirtland Air Force Base East, Albuquerque, New Mexico
			87115.  82 pp.
		O'Neill, D. (1987).  IRIS Interim Data Distribution Format
		(SAC ASCII), Version 1.0 (12 November 1987).  Incorporated
		Research Institutions for Seismology, 1616 North Fort Myer
		Drive, Suite 1440, Arlington, Virginia 22209.  11 pp.
		Tull, J. (1987).  SAC User's Manual, Version 10.2, October 7,
		1987.  Lawrence Livermore National Laboratory, L-205,
		Livermore, California 94550.  ??? pp.
	Language:	C, hopefully ANSI standard
	Author:		Dennis O'Neill
	Revisions:	07/15/88  Dennis O'Neill  Initial preliminary release 0.9
		11/21/88  Dennis O'Neill  Production release 1.0
		09/19/89  Dennis O'Neill  corrected output string length
		05/01/92  Allen Nance  corrected CMPINC Header variable for SEED Dip definition
		sach.cmpinc = current_channel->dip + 90.0;
		01/19/01  Doug Neuhauser - reintegrated SAC ascii and binary output into
		this single routine.  Made ascii output more efficient.  Reindented code.
*/

#include <stdio.h>
#include <sys/param.h>

#include "rdseed.h"	/* SEED tables and structures */
#include "sac.h"	/* SAC format structures */


extern int Output_PnZs;
extern int EventDirFlag;
extern int read_summary_flag;
extern int output_endtime;
extern char micro_sec;

extern struct type48 *find_type_48_stage_0(struct response *);

char *summary_file_get_event();
char *get_event_dir_name();
char *YMDtoYDDD();


struct type53 *find_type_53();
struct type43 *find_type_43();
struct type34 *find_type_34();


float get_A0();
 
char strlst();

int sac_reverse_seismic_data();
extern char prev_quality;

void output_sac(data_hdr, offset, asciiflag)
struct data_hdr *data_hdr;
int offset;
int asciiflag;
{

	FILE *outfile;			/* output file pointer */
	char outfile_name[100], channel[10];	/* output file name */
	struct sac sach;			/* SAC header structure */
	int i, j,k;				/* counter */
	char character[8+1];	/* for character transfer */
	int ascii;		/* switch for ASCII output */
	int binary;		/* switch for binary output */
	int reverse_flag;	/* Data reversal flag */
	double dip, azimuth;	/* temp holding for these variables */
	struct type48 *type_48;

	char wrkstr[1024], event_time[64];
	struct time ev_time;
	struct time data_hdr_endtime;
	struct time trace_time;
	struct type34 *type_34;
	double duration;

	struct response *response; int flag;

	char orig_dir[MAXPATHLEN];

	getcwd(orig_dir, MAXPATHLEN);

	chdir(output_dir);

	/* select ASCII or binary output (binary chosen here) */
	ascii = asciiflag;		

	binary = !ascii;

	/* initialize SAC Header to all nulls */
	sach = sac_null;

	for (k=0;k<data_hdr->num_mux_chan;k++)
	{
		if (current_channel == NULL)
		{
			fprintf(stderr, "\tERROR - Unexpected End of Multiplexed Channel List\n");
			chdir(orig_dir);
			return;
		}

		reverse_flag = 0;
		for (i=0;i<10;i++) 
			channel[i] = 0;

		strcpy(channel,current_channel->channel);

        	if (data_hdr->num_mux_chan > 1) 
		{
                	int i;

                	for (i=0; i<3; i++) {
                        	if (channel[i] == ' ' || 
				    channel[i] == '\0') 
					break;
			}

                	if (i > 2) 
				i = 2;

                	channel[i] = data_hdr->mux_chan_name[k];
        	}

		dip = current_channel->dip;
		azimuth = current_channel->azimuth;

		reverse_flag = check_for_reversal(dip, azimuth, channel[2]);


		flag = FALSE;
		for (response = current_channel->response_head; 
		     response != NULL; response = response->next)
		{
			reverse_flag &= 1;

			if (response->type == 'S') { 
				if ((response->ptr.type58)->stage == 0)
				{
					if (((response->ptr.type58)->sensitivity < 0.0) && 
					    (check_reverse & 2))
						reverse_flag |= 2;

					sach.scale = (float)(response->ptr.type58)->sensitivity;
					flag = TRUE;
				}
			} else if (response->type == 'R') {
				type_48 = find_type_48_stage_0(response);
				if (type_48 != NULL) {
					if ((type_48->sensitivity < 0.0) && 
					    (check_reverse & 2))
						reverse_flag |= 2;

					sach.scale = (float)type_48->sensitivity;
					flag = TRUE;
				}
			}
		}
		if (!flag && (check_reverse & 2))
			fprintf(stderr, "Warning - Stage Zero Not Found on Gain Reversal check\n");
 
		if (check_reverse & 1)
		{
			if (reverse_flag & 1)
				fprintf (stderr, "Warning... Azimuth/Dip Reversal found %s.%s, Data will be automatically inverted\n           Response Information will not be modified\n",
					 current_station->station, channel);
		}
		else
		{
			if (reverse_flag & 1)
				fprintf (stderr, "Warning... Azimuth/Dip Reversal found %s.%s, Data inversion was not selected\n",
					 current_station->station, channel);
			reverse_flag &= 2;
		}

		if (check_reverse & 2)
		{
			if (reverse_flag & 2)
				fprintf (stderr, "Warning... Gain Reversal found %s.%s, Data will be automatically inverted\n           Response Information will not be modified\n",
					 current_station->station, channel);
		}
		else
		{
			if (reverse_flag & 2)
				fprintf (stderr, "Warning... Gain Reversal found %s.%s, Data inversion was not selected\n",
					 current_station->station, channel);
			reverse_flag &= 1;
		}

		if (reverse_flag == 3)
		{
			reverse_flag = 0;		/* Double inversion */
			fprintf (stderr, "Warning... Gain and Dip/Azimuth Reversal found %s.%s, Data was not inverted\n",
				 current_station->station, channel);
		}

		if (reverse_flag & 1)
			switch (channel[2])
			{
			case 'Z':
				dip = -90.0;
				break;
			case 'N':
				azimuth = 0.0;
				break;
			case 'E':
				azimuth = 90.0;
				break;
			case 'A':
				dip = -60.0;
				azimuth = 0.0;
				break;
			case 'B':
				dip = 60.0;
				azimuth = 120.0;
				break;
			case 'C':
				dip = -60.0;
				azimuth = 240.0;
				break;
			default:
				break; 
			}

		if (reverse_flag & 2) sach.scale = -sach.scale;

/*                 +=======================================+                 */
/*=================|          Build the SAC header         |=================*/
/*                 +=======================================+                 */


		if (data_hdr->nsamples == 0)
		{
			fprintf(stderr,"\tWARNING (output_sac):  Output Data Contains No Samples\n");
			chdir(orig_dir);
			return;
		}

		/* give values to SAC-required variables */
		sach.delta = 1 / data_hdr->sample_rate;

		sach.b = ((data_hdr->time.fracsec - ((data_hdr->time.fracsec/10)*10)) / 10000.0) + (micro_sec / 1000000.0);

		sach.e = ((double) data_hdr->nsamples - 1) / ((double) data_hdr->sample_rate);
		sach.npts = data_hdr->nsamples;
		sach.iftype = ITIME;			/* known a priori */
		sach.leven = TRUE;			/* known a priori */

		/* give values available from struct data_hdr to SAC optional variables */
		/* record start time */
		sach.nzyear = data_hdr->time.year;
		sach.nzjday = data_hdr->time.day;
		sach.nzhour = data_hdr->time.hour;
		sach.nzmin  = data_hdr->time.minute;
		sach.nzsec  = data_hdr->time.second;
		sach.nzmsec = data_hdr->time.fracsec / 10;	/* convert to msec */

		/* save trace time for later computation */
		trace_time.year    = data_hdr->time.year;
		trace_time.day     = data_hdr->time.day;
		trace_time.hour    = data_hdr->time.hour;
		trace_time.minute  = data_hdr->time.minute;
		trace_time.second  = data_hdr->time.second;
		trace_time.fracsec = data_hdr->time.fracsec;


		/* station and component names */
		sprintf (character, "%-8.8s", data_hdr->station);
		strncpy (sach.kstnm, character, 8);
		sprintf (character, "%-8.8s", channel);
		strncpy (sach.kcmpnm, character, 8);
		sprintf (character, "%-8.8s", data_hdr->network);
		strncpy(sach.knetwk, character, 8);
		sprintf (character, "%-8.8s", data_hdr->location);
		strncpy(sach.khole, character, 8);

		/* give values available from SEED tables to SAC optional variables */
		sach.stla = current_channel->latitude;
		sach.stlo = current_channel->longitude;
		sach.stel = current_channel->elevation;
		sach.stdp = current_channel->local_depth;

        	type_34 = find_type_34(type34_head,
				current_channel->signal_units_code);

		sach.idep = 5; /* Unknown */

		sach.cmpaz = azimuth;
		sach.cmpinc = dip + 90.0; /* SEED dip is 90 degrees off from SAC dip */

		if (read_summary_flag)
		{
			char *p;

			memset(wrkstr, 0, sizeof(wrkstr));

			/* recover current event from summary file */
			strncpy(wrkstr, summary_file_get_event(), 511);

			/* skip the source */

			/* source */
			p = strtok(wrkstr, ",");

			if (p == NULL)
			{
				fprintf(stderr, "Error - output_sac, unable to extract event info for sac header!\n");
				fprintf(stderr, "Event: %s\n", 
					summary_file_get_event());

				break;
			}
		
			/* date/time */
			p = strtok(NULL, ","); 

			if (p == NULL) 
			{        
				fprintf(stderr, "Error - output_sac, unable to extract event info for sac header!\n"); 
				fprintf(stderr, "Event: %s\n", 
					summary_file_get_event()); 
 
				break; 
			}

			/* save ev time for later computation */
			strcpy(event_time, p);

         
			/* latitude */
			p = strtok(NULL, ","); 
 
			if (p == NULL)  
			{         
				fprintf(stderr, "Error - output_sac, unable to extract event info for sac header!\n"); 
				fprintf(stderr, "Event: %s\n", 
                                        summary_file_get_event());
  
				break; 
			}
         
			sach.evla = atof(p); 
   		
			/* longitude */ 
			p = strtok(NULL, ","); 
  
			if (p == NULL)  
			{          
				fprintf(stderr, "Error - output_sac, unable to extract event info for sac header!\n");  
				fprintf(stderr, "Event: %s\n",  
                                        summary_file_get_event()); 
   
				break;  
			} 
        
			sach.evlo = atof(p);

			/* depth */ 
			p = strtok(NULL, ","); 
  
			if (p == NULL)  
			{          
				fprintf(stderr, "Error - output_sac, unable to extract event info for sac header!\n");  
				fprintf(stderr, "Event: %s\n",  
                                        summary_file_get_event()); 
   
				break;  
			} 
       
			sach.evdp = atof(p) * 1000;  /* convert to meters */
	
			/* convert from YY/MM/DD... to time structure */
			/* do here after all strtoks are done */
			timecvt(&ev_time, event_time);
		
		}
		else
			/* event lat/lon from hypo B071 */
			if (type71_head != NULL)
			{
				sach.evla = type71_head->latitude;
				sach.evlo = type71_head->longitude;
				sach.evdp = type71_head->depth * 1000; /* convert to meters */
				timecvt(&ev_time, type71_head->origin_time);

			}
		
		if (read_summary_flag || type71_head != NULL)
		{
			int error = 0;

			error = delaz(sach.evla, sach.evlo,
				      sach.stla, sach.stlo,
				      &sach.gcarc, &sach.az, &sach.baz);


			if (error)
			{
				fprintf(stderr, "Error - unable to compute event distance/azimuth and back azimuth for station %s; channel %s!\n", 
					current_station->station, 
					current_channel->channel);

				sach.gcarc = 0; sach.az = 0; sach.baz = 0;
			}
			else
				/* 111.1 KM per Degree - gcarc is in degrees */
				sach.dist = 111.1 * sach.gcarc;

			/* timedif gives back 10000ths, convert to seconds */
			sach.o = (float) timedif(trace_time, ev_time) / 10000;
					
		}	/* if event lat/lon/depth */

		/* mysterious LLL-set values */
		sach.internal1 = 2.0;
		sach.internal4 = 6;
		sach.internal5 = 0;
		sach.internal6 = 0;
		sach.unused27 = FALSE;

		/* not sure if these are needed, but they might be. Values might be wrong */
		sach.lpspol = FALSE;
		sach.lcalda = TRUE;

/*                 +=======================================+                 */
/*=================|  build name for and open output file  |=================*/
/*                 +=======================================+                 */

		/* 1988.023.15.34.08.2800.ANMO.SPZ is the filename for a seismogram 
		 *	from year 1988, Julian day 23, 15:34:08.2800 UT, recorded 
		 *	at station ANMO from component SPZ. 
		 */

		/* if requested from WEED, place into subdirectory */
		if (EventDirFlag)
		{
			char dirname[MAXPATHLEN];

			strcpy(dirname, get_event_dir_name());

			if (!dir_exists(dirname))
			{
				if (mkdir(dirname, 0777) == -1)
				{
					fprintf(stderr, "Unable to create event directory. Using current directory!\n");
					perror("output_sac");
					strcpy(dirname, "./");
				}
 
			}
		
			chdir(dirname);
 
		}



		if (output_endtime == TRUE) { 
			duration  = 
                   	((double)(data_hdr->nsamples)*10000)/data_hdr->sample_rate;
                	data_hdr_endtime = timeadd_double(data_hdr->time, duration);
			sprintf (outfile_name, 
			 "%04d.%03d.%02d.%02d.%02d.%04d_%04d.%03d.%02d.%02d.%02d.%04d.%s.%s.%s.%s.%c.SAC%s",
			 data_hdr->time.year,
			 data_hdr->time.day,
			 data_hdr->time.hour,
			 data_hdr->time.minute,
			 data_hdr->time.second,
			 data_hdr->time.fracsec,
			 data_hdr_endtime.year,
			 data_hdr_endtime.day,
			 data_hdr_endtime.hour,
			 data_hdr_endtime.minute,
			 data_hdr_endtime.second,
			 data_hdr_endtime.fracsec,
			 type10.version >= 2.3 ? data_hdr->network : "",
			 data_hdr->station,
			 data_hdr->location,
			 channel,
			 // input.type,
			 prev_quality,
			 (ascii) ? "_ASC" : "");
		} else {
			sprintf (outfile_name,
                         "%04d.%03d.%02d.%02d.%02d.%04d.%s.%s.%s.%s.%c.SAC%s",
                         data_hdr->time.year,
                         data_hdr->time.day,
                         data_hdr->time.hour,
                         data_hdr->time.minute,
                         data_hdr->time.second,
                         data_hdr->time.fracsec,
                         type10.version >= 2.3 ? data_hdr->network : "",
                         data_hdr->station,
                         data_hdr->location,
                         channel,
                         // input.type,
			 prev_quality,
                         (ascii) ? "_ASC" : "");
		}

		if ((outfile = fopen (outfile_name, "w+")) == NULL)
		{
			fprintf (stderr, "\tWARNING (output_sac):  ");
			fprintf (stderr, "Output file %s is not available for writing.\n",
				 outfile_name);
			fprintf (stderr, "\tExecution continuing.\n");

			chdir(orig_dir);
		
			return;
		}

/*                 +=======================================+                 */
/*=================|        write a SAC ASCII file         |=================*/
/*                 +=======================================+                 */

		if (ascii)
		{
			/* describe the file being written */
			printf ("Writing %s.%s.%s.%s, %5d samples (ASCII),",
				type10.version >= 2.3 ? data_hdr->network : "",
				data_hdr->station,
				data_hdr->location,
				channel,
				data_hdr->nsamples);

			printf (" starting %04d,%03d %02d:%02d:%02d.%04d UT\n",
				data_hdr->time.year,
				data_hdr->time.day,
				data_hdr->time.hour,
				data_hdr->time.minute,
				data_hdr->time.second,
				data_hdr->time.fracsec);

			/* write the SAC header */
			fprintf (outfile, FCS, 
				 sach.delta, 
				 sach.depmin, 
				 sach.depmax, 
				 sach.scale, 
				 sach.odelta);
			fprintf (outfile, FCS, 
				 sach.b, 
				 sach.e, 
				 sach.o, 
				 sach.a, 
				 sach.internal1);
			fprintf (outfile, FCS, 
				 sach.t0, 
				 sach.t1, 
				 sach.t2, 
				 sach.t3, 
				 sach.t4);
			fprintf (outfile, FCS, 
				 sach.t5, 
				 sach.t6, 
				 sach.t7, 
				 sach.t8, 
				 sach.t9);
			fprintf (outfile, FCS, 
				 sach.f, 
				 sach.resp0, 
				 sach.resp1, 
				 sach.resp2, 
				 sach.resp3);
			fprintf (outfile, FCS, 
				 sach.resp4, 
				 sach.resp5, 
				 sach.resp6, 
				 sach.resp7, 
				 sach.resp8);
			fprintf (outfile, FCS, 
				 sach.resp9, 
				 sach.stla, 
				 sach.stlo, 
				 sach.stel, 
				 sach.stdp);
			fprintf (outfile, FCS, 
				 sach.evla,
				 sach.evlo,
				 sach.evel,
				 sach.evdp,
				 sach.unused1);
			fprintf (outfile, FCS, 
				 sach.user0,
				 sach.user1,
				 sach.user2,
				 sach.user3,
				 sach.user4);
			fprintf (outfile, FCS, 
				 sach.user5,
				 sach.user6,
				 sach.user7,
				 sach.user8,
				 sach.user9);
			fprintf (outfile, FCS, 
				 sach.dist,
				 sach.az,
				 sach.baz,
				 sach.gcarc,
				 sach.internal2);
			fprintf (outfile, FCS, 
				 sach.internal3,
				 sach.depmen,
				 sach.cmpaz,
				 sach.cmpinc,
				 sach.unused2);
			fprintf (outfile, FCS, 
				 sach.unused3,
				 sach.unused4,
				 sach.unused5,
				 sach.unused6,
				 sach.unused7);
			fprintf (outfile, FCS, 
				 sach.unused8,
				 sach.unused9,
				 sach.unused10,
				 sach.unused11,
				 sach.unused12);
			fprintf (outfile, ICS, 
				 sach.nzyear,
				 sach.nzjday,
				 sach.nzhour,
				 sach.nzmin,
				 sach.nzsec);
			fprintf (outfile, ICS, 
				 sach.nzmsec,
				 sach.internal4,
				 sach.internal5,
				 sach.internal6,
				 sach.npts);
			fprintf (outfile, ICS, 
				 sach.internal7,
				 sach.internal8,
				 sach.unused13,
				 sach.unused14,
				 sach.unused15);
			fprintf (outfile, ICS, 
				 sach.iftype,
				 sach.idep,
				 sach.iztype,
				 sach.unused16,
				 sach.iinst);
			fprintf (outfile, ICS, 
				 sach.istreg,
				 sach.ievreg,
				 sach.ievtyp,
				 sach.iqual,
				 sach.isynth);
			fprintf (outfile, ICS, 
				 sach.unused17,
				 sach.unused18,
				 sach.unused19,
				 sach.unused20,
				 sach.unused21);
			fprintf (outfile, ICS, 
				 sach.unused22,
				 sach.unused23,
				 sach.unused24,
				 sach.unused25,
				 sach.unused26);
			fprintf (outfile, ICS, 
				 sach.leven,
				 sach.lpspol,
				 sach.lovrok,
				 sach.lcalda,
				 sach.unused27);
			fprintf (outfile, CCS2, 
				 sach.kstnm,
				 sach.kevnm);
			fprintf (outfile, CCS1, 
				 sach.khole,
				 sach.ko,
				 sach.ka);
			fprintf (outfile, CCS1, 
				 sach.kt0,
				 sach.kt1,
				 sach.kt2);
			fprintf (outfile, CCS1, 
				 sach.kt3,
				 sach.kt4,
				 sach.kt5);
			fprintf (outfile, CCS1, 
				 sach.kt6,
				 sach.kt7,
				 sach.kt8);
			fprintf (outfile, CCS1, 
				 sach.kt9,
				 sach.kf,
				 sach.kuser0);
			fprintf (outfile, CCS1, 
				 sach.kuser1,
				 sach.kuser2,
				 sach.kcmpnm);
			fprintf (outfile, CCS1, 
				 sach.knetwk,
				 sach.kdatrd,
				 sach.kinst);

			j = k*(seis_buffer_length/data_hdr->num_mux_chan);

			/* reverse the polarity of the data if necessary */
			if (reverse_flag) {
				sac_reverse_seismic_data ( offset, j, data_hdr->nsamples, outfile_name);
			}

			/* write the SAC data */
			/* try to be somewhat efficient about the number of calls to fprint */
			for (i=0; i<data_hdr->nsamples; i+=5)
			{
				if (i+5 < data_hdr->nsamples) {
				fprintf (outfile, "%15.7g%15.7g%15.7g%15.7g%15.7g\n", 
					 seismic_data[offset+i+j],
					 seismic_data[offset+i+j+1],
					 seismic_data[offset+i+j+2],
					 seismic_data[offset+i+j+3],
					 seismic_data[offset+i+j+4]);
				}
				else {
					while (i < data_hdr->nsamples) {
						fprintf (outfile, "%15.7g", 
							 seismic_data[offset+i+j]);
						i++;

					}
					fprintf (outfile, "\n");
				}
				fflush(outfile);
			}
		}

/*                 +=======================================+                 */
/*=================|       write a SAC binary file         |=================*/
/*                 +=======================================+                 */

		if (binary)
		{
			/* describe the file being written */
			printf ("Writing %s.%s.%s.%s, %5d samples (binary),",
				type10.version >= 2.3 ? data_hdr->network : "",
				data_hdr->station,
				data_hdr->location,
				channel,
				data_hdr->nsamples);
			printf (" starting %04d,%03d %02d:%02d:%02d.%04d UT\n",
				data_hdr->time.year,
				data_hdr->time.day,
				data_hdr->time.hour,
				data_hdr->time.minute,
				data_hdr->time.second,
				data_hdr->time.fracsec);

			/* write the SAC header */
			if (fwrite (&sach, sizeof (struct sac), 1, outfile) != 1)
			{
				fprintf (stderr, "\tWARNING (output_sac):  ");
				fprintf (stderr, "failed to properly write SAC header to %s.\n",
					 outfile_name);
				fprintf (stderr, "\tExecution continuing.\n");
			}
			
			j = k*(seis_buffer_length/data_hdr->num_mux_chan);

			/* reverse the polarity of the data if necessary */
			if (reverse_flag) {
				sac_reverse_seismic_data ( offset, j, data_hdr->nsamples, outfile_name);
			}

			/* write the SAC data */
			if (fwrite (&seismic_data[offset+j], data_hdr->nsamples * sizeof (float), 
				    1, outfile) != 1)
			{
				fprintf (stderr, "\tWARNING (output_sac):  ");
				fprintf (stderr, "failed to properly write SAC data to %s.\n",
					 outfile_name);

				perror("output_sac()");

				fprintf (stderr, "\tExecution continuing.\n");
			}

		}

		fclose (outfile);

		current_channel = current_channel->next;

	}		/* the BIG k loop If multiplexed */

	chdir(orig_dir);

	return;

}


/* ------------------------------------------------------------------------- */
int sac_reverse_seismic_data (offset, mux_offset, nsamples, outfile_name) 
int offset;
int mux_offset;
int nsamples;
char *outfile_name;
{
	int i, j;
	char wrkstr[200];
	for (i=0; i<nsamples; i++)
		seismic_data[offset+i+mux_offset] = -seismic_data[offset+i+mux_offset];

	sprintf(wrkstr, "Data reversal initiated for SAC file %s", outfile_name);
	rdseed_alert_msg_out(wrkstr);
	return (nsamples);
}

/* ------------------------------------------------------------------------- */
int output_polesNzeros()



{
	void cnvt_end_time();

	struct time start;
	struct time end;

	char orig_dir[MAXPATHLEN];



	struct type52 *t_52 = current_channel;
	struct type50 *t_50 = current_station;

	current_station = type50_head;

	getcwd(orig_dir, MAXPATHLEN);

	chdir(output_dir);

	while (current_station)
	{
		/* check to see if this station was requested by the user */
		if (!chk_station(current_station->station))
		{
			current_station = current_station->next;
			continue;
		}

		if ((type10.version >= 2.3) && 
			!chk_network(current_station->network_code))
		{
			current_station = current_station->next;
            		continue;
		}

		/* check to see if this station lies within the requested time
		 * spans. Convert station time into time structure
		 */
		timecvt(&start, current_station->start);
		timecvt(&end, current_station->end);

		/* for chk_time to work, we need to convert zeros in the
		 * end time struct into really big numbers.
	 	 */

		/* probably should be done in timecvt() */
		cnvt_end_time(&end);
		
		if (!chk_time(start, end))
		{
			current_station = current_station->next;
           		continue;
		}
		
		/* now we have a good station, do the same for its channels */

		current_channel = current_station->type52_head;

		while (current_channel)
		{
			/* check to see if this station was requested by the user */ 
			if (!chk_channel(current_channel->channel)) 
			{   
				current_channel = current_channel->next;
				continue; 
			}    

			/* ignore LOG channels */
			if (strcasecmp(current_channel->channel, "LOG") == 0)
			{
				current_channel = current_channel->next;
                                continue;
			}
 
			/* check to see if this channel lies within the requested time   
			 * spans. Convert channel time into time structure   
			 */ 
			timecvt(&start, current_channel->start);            
			timecvt(&end, current_channel->end);    

			cnvt_end_time(&end);
 
			if (!chk_time(start, end))   
			{
				current_channel = current_channel->next; 
				continue;
			}
        
			/* now we have a good station/channel; write out poles */     
			write_out_PnZs(start, end);

			current_channel = current_channel->next;

		}		/* while channels */

		current_station = current_station->next;	
	
	}				/* while stations */

	current_station = t_50;	/* there maybe downwind ramifications, so
				 * leave as is 
				 */
	current_channel = t_52;

	chdir(orig_dir);

}
/* ----------------------------------------------------------------------- */
char determine_orient_code();


int write_out_PnZs(struct time start, struct time end)

{
	
	struct type34 *type_34;

	struct type53sub *poles;
	struct type53sub *zeros;

	float Sd, fn, fs, A0, calculated_A0;

	int num_zeros;
	int num_poles;
	int add_zeros;
	int finished;


	char transfer_type;	/* from SEED manual A laplace, B- analog, etc */	
	FILE *fptr;

	/* file name : SAC_PZS_Network_Station_Channel */
	char fname[200];

	struct response *response;

	char orient;

	poles = zeros = 0; 

	finished = FALSE;

	/* if multiplexed data, check for orientation for this channel */
	if (current_channel->subchannel > 0)
	{
		current_channel->channel[2] = 
			determine_orient_code(current_channel); 

		current_channel->channel[3] = 0;
	}

	sprintf(fname, "SAC_PZs_%s_%s_%s_%s_%04d.%03d.%02d.%02d.%02d.%04d_%04d.%03d.%02d.%02d.%02d.%04d",
                                current_station->network_code ?
                                                current_station->network_code :
                                                "NA",
                                current_station->station,
                                current_channel->channel,
                                current_channel->location,
				start.year,
				start.day,
				start.hour,
				start.minute,
				start.second, 
				start.fracsec, 
				end.year,
				end.day,
				end.hour,
				end.minute,
				end.second, end.fracsec);

	fptr = fopen(fname, "a");

	if (fptr == NULL)
	{
		fprintf(stderr, "Unable to open poles and zeros file. Going on.\n\n");

		perror("output_polesNzeros()");

		return -1;

	}

        /* from the type 34 we determine the ground motion type,
         * displacement, velocity, or acceleration
         */
        type_34 = find_type_34(type34_head,
                                current_channel->signal_units_code);


        if (type_34 == NULL)
        {
                fprintf(stderr, "Warning - couldn't find the abbrevation for the signal units code! Signal units code =%d\n", current_channel->signal_units_code);

                fprintf(stderr, "For station: %s; channel: %s\n\n", current_station->station, current_channel->channel);

                fprintf(stderr, "Setting the number of zeros to add to 0\n");
                add_zeros = 0;
        }
        else
                determine_gamma(type_34, &add_zeros);  /* see ah_resp.c */

	A0 = get_A0(&poles, &zeros,
                        &num_poles, &num_zeros,
                        &Sd, add_zeros, 
			current_channel->response_head,
			99999);

	if (A0 == -1) 
	{
		/* error condition */
	       	fclose(fptr);

		if (poles != NULL)
			free(poles);

		if (zeros != NULL)
			free(zeros);


	        return 1;

	}


	print_PnZs(poles,
       			zeros,
              		num_poles,
               		num_zeros,
               		fptr);
			
       	if (fprintf(fptr, "CONSTANT %e\n", Sd * A0) == -1)
       	{
		fprintf(stderr, "\tWARNING (output_polesNzeros():  ");
               	fprintf(stderr, "\tUnable to write to file\n");

               	perror("output_resp()");
 
               	fprintf(stderr, "\tExecution continuing.\n");
 
               	fclose(fptr);

               	return;
 
       	}

	if (poles != NULL) 
		free(poles);

	if (zeros != NULL) 
		free(zeros); 

	fclose(fptr);


	return 1;

} 				/* writeout_PnZs() */

/* ------------------------------------------------------------------------- */
int print_PnZs(ps, zs, n_ps, n_zs, fptr)
struct type53sub *ps;	/* array of poles */
struct type53sub *zs;	/* array of zeros */
int n_ps;		/* number of poles */
int n_zs;		/* number of zeros */
FILE *fptr;

{
	int i;

	/* Print number of zeros */
	fprintf(fptr, "ZEROS %d\n", n_zs);

	for (i = 0; i < n_zs; i++)
		if ((zs[i].real == 0) && (zs[i].imag == 0))
			continue;
		else
                        if (fprintf(fptr, "%4.4f  %4.4f\n",
                                        zs[i].real,
                                        zs[i].imag) == -1)
                        {
                                fprintf(stderr, "\tWARNING (print_PnZs():  ");
                                fprintf(stderr, "\tUnable to write to file\n");
 
                                perror("print_PnZs()");
 
                                fprintf (stderr, "\tExecution continuing.\n");
                        }
 

	/* Print number of poles */ 
        fprintf(fptr, "POLES %d\n", n_ps);    

        for (i = 0; i < n_ps; i++)   
		if ((ps[i].real == 0) && (ps[i].imag == 0)) 
                        continue;
                else 
			if (fprintf(fptr, "%4.4f  %4.4f\n",
						ps[i].real,
						ps[i].imag) == -1)
			{
				fprintf(stderr, "\tWARNING (print_PnZs():  ");
				fprintf(stderr, "\tUnable to write to file\n");

				perror("printPnZs()");

				fprintf(stderr, "\tExecution continuing.\n");

			}

	return;

}
 
/* -------------------------------------------------------------- */
/* -------------------------------------------------------------- */

void cnvt_end_time(e)
struct time *e;

{

		if (e->year == 0)
			e->year = 99999;	/* that outta do it */
		if (e->day == 0)
			e->day = 9999;
		if (e->hour == 0)
			e->hour = 24;
		if (e->minute == 0)
			e->minute = 60;
		if (e->second == 0)
			e->second = 60;
		if (e->fracsec == 0)
			e->fracsec = 99999;
}


char *get_event_dir_name()

{

	static char dirname[100];

	char this_event[128], this_date_time[23], wrkstr[40];
	char *p;

	memset(this_event, 0, sizeof(this_event));

	/* we only need the event line up to the data and time */
	strncpy(this_event, summary_file_get_event(), 100);

	/* skip the source */
	p = strtok(this_event, ",");

	/* copy entire date/time field */
	p = strtok(NULL, ",");

	if (p == NULL)
	{
		p = "1900.00.00.00.00.00.0";
	}
		
	strcpy(this_date_time, p);
	
	/* date and time */
       	p = strtok(this_date_time, "/");

	if (p == NULL)
		p = "";

	/* use atoi() to strip spaces */
	sprintf(dirname, "Event_%d.", atoi(p));

	/* month */
	p = strtok(NULL, "/");

	if (p == NULL)
		p = "";

	sprintf(wrkstr, "%02d", atoi(p));
	strcat(dirname, wrkstr);

	/* day */
	p = strtok(NULL, " ");

	if (p == NULL)
		p = "";
        
	sprintf(wrkstr, ".%02d", atoi(p)); 
	strcat(dirname, wrkstr);
 
	/* hour:minute:second.frac */
	p = strtok(NULL, ":");

	if (p == NULL)
		p = "";

	sprintf(wrkstr, ".%02d", atoi(p)); 
	strcat(dirname, wrkstr);

	/* minute */
	p = strtok(NULL, ":");
 
	if (p == NULL)
		p = "";
	
	sprintf(wrkstr, ".%02d", atoi(p)); 
	strcat(dirname, wrkstr);
 
	/* seconds */
	p = strtok(NULL, ".");
 
	if (p == NULL)
		p = "";

	sprintf(wrkstr, ".%02d", atoi(p)); 
	strcat(dirname, wrkstr);

	/* fractional part */
	p = strtok(NULL, ",");
 
	if (p == NULL)
		p = "";
 
	sprintf(wrkstr, ".%02d", atoi(p));
	strcat(dirname, wrkstr);
 

	return dirname;

}		/* get_event_dir_name() */

/* -------------------------------------------------------------------- */
int check_for_reversal(dip, azimuth, c)
float dip; 
float azimuth;
char c;

{

	int reverse_flag = 0;

	switch (c)
	{
		case 'Z':
			if (dip==90.0 && azimuth==0.0)
				reverse_flag = 1;
			break;
		case 'N':
			if (dip==0.0 && azimuth==180.0)
				reverse_flag = 1;
			break;
		case 'E':
			if (dip==0.0 && azimuth==270.0)
				reverse_flag = 1;
			break;
		case 'A':
			if (dip==60.0 && azimuth==180.0)
				reverse_flag = 1;
			break;
		case 'B':
			if (dip==60.0 && azimuth==300.0)
				reverse_flag = 1;
			break;
		case 'C':
			if (dip==60.0 && azimuth==60.0)
				reverse_flag = 1;
			break;
		case 'H' : case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9': case '0': case 'O':
			break;
		default:
			fprintf(stderr, "Warning... Invalid Channel Direction character on %s,%s\n", current_station->station, current_channel->channel);
			break; 

	}		/* switch */

	return reverse_flag;

}

/* ------------------------------------------------------------------------- */
