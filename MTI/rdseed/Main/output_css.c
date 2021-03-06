/*===========================================================================*/
/* SEED reader     |              output_css               |    subprocedure */
/*===========================================================================*/
/*
	Name:	output_css
	Purpose:build a seismogram file from the SEED header tables
				and data files and writes output seismogram files.
		This procedure writes output in CSS format 
	Usage:	void output_css ();
			output_css (data_hdr, offset);
	Input:	pointer to current data and offset in data buffer and 
		gets its data from globally-available tables and files
	Output:	none (writes a seismogram file; seismogram files are named by
		station, component, beginning time, and a tag; for example,
		ANMO.SPZ.1988.01.23.15.34.08.CSS is the filename for a
		seismogram from year 1988, January 23, 15:34:08 UT,
		recorded at station ANMO from component SPZ.  Writes message
		to stderr describing the seismogram file being written.
	Called by:	time_span_out();
	Calls to:	
	Author:		Allen Nance
	Revisions:	03/31/91  Base on Dennis O'Neill's (09/19/89) output_data.
				01/19/95  CL - added disp_factor * frequency as per Pete Davis

*/

#include "rdseed.h"		/* SEED tables and structures */
#include <stdio.h>
#include <math.h>
#include <sys/errno.h>
#include <sys/stat.h>
#include <math.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <unistd.h>

#define STRUPPERCASE(s) { char *p = s; while(*p) *p++ = toupper(*p); }

#define ORID 1

/*#define isaleap(year) ((((year)%100 != 0) && ((year)%4 == 0)) || ((year)%400 == 0)) */

struct type58 *find_type_58_stage_0();

static int siteid;
char *get_event_dir_name();
char *get_net();
struct type33 *find_type_33();
char *get_src_name();

extern int EventDirFlag;
extern struct type48 *find_type_48_stage_0(struct response *);

void output_css (data_hdr, offset)
struct data_hdr *data_hdr;
int offset;
{
	int	*i_seismic_data;	/* pointer for data storage */
	FILE 	*outfile;		/* output file pointer */
	char 	outfile_name[80], channel[12];	/* output file name */
	int 	i, j, k;	/* counters */
	char 	character[12];	/* for character transfer */
	int 	ascii;		/* switch for ASCII output */
	int 	binary;		/* switch for binary output */
	int 	reverse_flag;	/* Data reversal flag */
	time_t	time_sec;
	double  dip;		/* temp holding for these variables */
	double  azimuth;	/* temp holding for these variables */
	double  calib, calper;	/* wfdisc calibration parms */
	struct	time	stime;	/* start time of channel info */
	struct	tm	*ltime;
	char	lddate[20];	/* current date and time */
	int		wfid;	/* wfdisc id variable */
	struct	stat statbuf;	/* file status buffer */
	char Wfdisc_buf[288];
	struct type48 *type_48;

	char station[20];
	char network[20];

	char event_dir[MAXPATHLEN];
	char orig_dir[MAXPATHLEN];

	/* select ASCII or binary output (binary chosen here) */
	ascii = FALSE;
	binary = !ascii;

	i_seismic_data = (int *) seismic_data;	/* Copy buffer pointer */

	time(&time_sec);
	ltime = localtime(&time_sec);
	strftime(lddate, 18, "%D %T", ltime);

	getcwd(orig_dir, MAXPATHLEN);

	chdir(output_dir);

	if (EventDirFlag)
	{
		strcpy(event_dir, get_event_dir_name());

		if (!dir_exists(event_dir))
			if (mkdir(event_dir, 0777) == -1)
			{
				fprintf(stderr, "Unable to create event directory. Using current directory!\n");
				perror("output_css");
				strcpy(event_dir, ".");
			}
		
		chdir(event_dir);
	}
 
	for (k=0;k<data_hdr->num_mux_chan;k++)
	{
		if (current_channel == NULL)
		{
			fprintf(stderr, "\tERROR - Unexpected End of Multiplexed Channel List\n");

			chdir(orig_dir);

			return;
		}

		reverse_flag = 0;
		for (i=0;i<10;i++) channel[i] = 0;
			strcpy(channel,current_channel->channel);
		if (data_hdr->num_mux_chan > 1) channel[strlen(channel)] = data_hdr->mux_chan_name[k];
		if (check_reverse & 1)

		dip = 0.0;	/* for some strange reason these two variables */
		azimuth = 0.0;	/* had to be inited to operate properly */

		dip = current_channel->dip;
		azimuth = current_channel->azimuth;

		check_for_reversal(dip, azimuth, channel[2]);

		calib = 0.0;			/* default scaling info */
		calper = 0.0;

	{
		struct response *response; int flag;
		struct type34 *type34;
		char temp[30];
		double disp_factor;
		struct type58 *t_58;

		int calib_zero_flag = 0;

		t_58 = find_type_58_stage_0(current_channel->response_head);

		if (t_58 == NULL)
    		{
       			fprintf(stderr, 
				"Warning - couldn't find stage 0 - blockette (58)!!\n");

        		fprintf(stderr, "For station: %s; channel: %s\n",
                    		current_station->station, current_channel->channel);

			fprintf(stderr,"Calibration variable will be set to Zero\n");
			calib_zero_flag = 1;

    		}


/* look for velocity or acceleration channels, AH only likes displacement */
/* so integrate response by deleting zeroes */

		disp_factor = 1.0;
		if (t_58 != NULL)
		for (type34 = type34_head; type34 != NULL; type34 = type34->next)
		{
			if (type34->code == current_channel->signal_units_code)
			{
				if (type34->description != 0)
					strncpy(temp, 
						type34->description, 
						30);
				else
					strcpy(temp, "");

				strupr(temp);

				if (strstr(temp,"VEL") != 0)
					disp_factor = 2.0*M_PI*t_58->frequency;
					
				if (strstr(temp,"ACCEL") != 0)
					disp_factor = 4.0*M_PI*M_PI*t_58->frequency;

				break;

			}
		}

		flag = FALSE;
		for (response = current_channel->response_head; response != NULL; response = response->next)
		{
			if (response->type == 'S') {
				if ((response->ptr.type58)->stage == 0) {
					if (((response->ptr.type58)->sensitivity < 0.0) && (check_reverse & 2))
					reverse_flag |= 2;
	
					if (calib_zero_flag)
						calib = 0;
					else
						calib = 1.0/((response->ptr.type58->sensitivity*disp_factor)/1000000000.0);
	
					calper = 1.0/(response->ptr.type58->frequency);
		
					flag = TRUE;
				}

			} else if (response->type == 'R') {
				type_48 = find_type_48_stage_0(response);
				if (type_48 != NULL) {
					if ((type_48->sensitivity < 0.0) && 
					    (check_reverse & 2))
						reverse_flag |= 2;

					if (calib_zero_flag)
						calib = 0;
					else
						calib = 1.0/(((float)type_48->sensitivity*disp_factor)/1000000000.0);
	
					calper = 1.0/((float)type_48->frequency);

					flag = TRUE;
				}
			}
		}

		if (!flag && (check_reverse & 2))
			fprintf(stderr, "Warning - Stage Zero Not Found on Gain Reversal check\n");
	}

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
		switch (strlst(channel))
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

		if (reverse_flag & 2) calib = -calib;

		if (data_hdr->nsamples == 0)
		{
			fprintf(stderr,"Output Data Contains No Samples\n");
			chdir(orig_dir);

			return;
		}
			
	 	if (binary)
		{
	
			/* WFDISC information */

		if (access("rdseed.wfdisc", R_OK)) wfid = 1;
		else
		{
			stat("rdseed.wfdisc", &statbuf);
			wfid = statbuf.st_size/284 + 1;
		}

		time_sec  = data_hdr->time.second;
		time_sec += data_hdr->time.minute  * 60;
		time_sec += data_hdr->time.hour    * 3600;
		time_sec += (data_hdr->time.day-1) * 3600 * 24;

		for (i=1971; i<= data_hdr->time.year; i++)
		{
			if (isaleap(i-1)) { time_sec += 366*24*3600; }

			else  { time_sec += 365*24*3600; }
		}

  		sprintf(&Wfdisc_buf[0], "%-6s ", data_hdr->station);
  		sprintf(&Wfdisc_buf[7], "%-8s ", channel);
 		sprintf(&Wfdisc_buf[16], "%17.5f ", (double)time_sec + ((double)data_hdr->time.fracsec)/10000.0);

  		sprintf(&Wfdisc_buf[34], "%8d ", wfid);
  		sprintf(&Wfdisc_buf[43], "%8d ", -1);
		sprintf(&Wfdisc_buf[52], "%8d ", (data_hdr->time.year * 1000) + data_hdr->time.day);
 		sprintf(&Wfdisc_buf[61], "%17.5f ",
			((double)time_sec + ((double)data_hdr->time.fracsec)/10000.0) +
		        ((double)(data_hdr->nsamples-1)/data_hdr->sample_rate));

		sprintf(&Wfdisc_buf[79], "%8d ", data_hdr->nsamples);
 		sprintf(&Wfdisc_buf[88], "%11.7f ", data_hdr->sample_rate);
 		sprintf(&Wfdisc_buf[100], "%16.6f ", calib);
  		sprintf(&Wfdisc_buf[117], "%16.6f ", calper);
  		sprintf(&Wfdisc_buf[134], "%-6s ", "-");
  		sprintf(&Wfdisc_buf[141], "%1s ", "o");
  		sprintf(&Wfdisc_buf[143], "%-2s ", "s4");
  		sprintf(&Wfdisc_buf[146], "%1s ", "-");

/*		sprintf (outfile_name, "%02d.%03d.%02d.%02d.%02d.%04d                                             ",
			data_hdr->time.year-1900,
			data_hdr->time.day,
			data_hdr->time.hour,
			data_hdr->time.minute,
			data_hdr->time.second,
			data_hdr->time.fracsec); */

		sprintf (outfile_name, ".                                                                 ");

		strcpy(&Wfdisc_buf[148], outfile_name);

/*		*(strchr(outfile_name,' ')) = 0;

		if (mkdir (outfile_name, S_IFDIR+0x1ff))
		{
			if (errno!=EEXIST)
			{
				fprintf (stderr,"\tWARNING (output_css):  ");
				fprintf (stderr,"Failed to make CSS directory %s, ERRNO = %d .\n",outfile_name, errno);
				fprintf (stderr, "\tExecution aborted.\n");
				perror("output_css()");
				chdir(orig_dir);
				return;
			}
		}

		if (chdir (outfile_name))
		{
			fprintf (stderr,"\tWARNING (output_css):  ");
			fprintf (stderr,"Failed to move to CSS directory %s .\n",outfile_name);
			fprintf (stderr, "\tExecution aborted.\n");

			perror("output_css");

			chdir(orig_dir);

			return;
		}
*/
		sprintf (outfile_name, "rdseed%08d.%c.w                    ",
			wfid, 
			input.type);

		strcpy(&Wfdisc_buf[213], outfile_name );

  		sprintf(&Wfdisc_buf[246], "%10d ", 0);
  		sprintf(&Wfdisc_buf[257], "%8d ", -1);
  		sprintf(&Wfdisc_buf[266], "%-17s\n", lddate);    

		*(strchr(outfile_name,' ')) = 0;

		if ((outfile = fopen (outfile_name, "w")) == NULL)
		{
			fprintf (stderr,"\tWARNING (output_css):  ");
			fprintf (stderr,"Unable to open output file %s \n",outfile_name);
			fprintf (stderr, "\tExecution aborted.\n");
	
			perror("output_css()");

			chdir(orig_dir);

			return;
		}


		/* describe the file being written */

		printf ("Writing %s, %s, %5d samples (binary),",
			data_hdr->station,channel,data_hdr->nsamples);
		printf (" starting %04d,%03d %02d:%02d:%02d.%04d UT\n",
			data_hdr->time.year,data_hdr->time.day,
			data_hdr->time.hour,data_hdr->time.minute,
			data_hdr->time.second,data_hdr->time.fracsec);			
			
		j = k*(seis_buffer_length/data_hdr->num_mux_chan);
		if (reverse_flag)
		{
			char wrkstr[200];

			for (i=0; i<data_hdr->nsamples; i++)
				i_seismic_data[offset+i+j] = (int) -seismic_data[offset+i+j];

			sprintf(wrkstr, "Data reversal initiated for CSS file %s", outfile_name);

			rdseed_alert_msg_out(wrkstr);
		}
		else
			for (i=0; i<data_hdr->nsamples; i++)
				i_seismic_data[offset+i+j] = (int) seismic_data[offset+i+j];



		/* write data */

			
		if (fwrite (&i_seismic_data[offset+j], data_hdr->nsamples * sizeof (int), 
		    1, outfile) != 1)
			{
				fprintf (stderr, "WARNING (output_css):  ");
				fprintf (stderr, "failed to properly write CSS data to %s.\n",
				outfile_name);
				perror("output_css()");

				fprintf (stderr, "\tExecution aborted.\n");
	
				chdir(orig_dir);

				return;
			}

		fclose (outfile);

		sprintf (outfile_name, "rdseed.wfdisc", css_filename);

		if ((outfile = fopen (outfile_name, "a")) == NULL)
		{
			fprintf (stderr,"\tWARNING (output_css):  ");
			fprintf (stderr,"Output file %s is not available for writing.\n",outfile_name);
			
			perror("output_css()");

			fprintf (stderr, "\tExecution continuing.\n");
		}
		

		if (fwrite (Wfdisc_buf, strlen(Wfdisc_buf), 1, outfile) != 1)
		{
			fprintf (stderr, "WARNING (output_css):  ");
			fprintf (stderr, "failed to properly write CSS WFDISC data to %s.\n", outfile_name);

			perror("output_css()");

			fprintf (stderr, "\tExecution continuing.\n");
		}

		fclose (outfile);

		timecvt(&stime, current_channel->start);

		siteid++;
		sprintf(&Wfdisc_buf[0], "%8d ",  siteid);
  		sprintf(&Wfdisc_buf[0], "%-6s ", data_hdr->station);
		sprintf(&Wfdisc_buf[7], " %04d%03d ", stime.year, stime.day);
 		sprintf(&Wfdisc_buf[16], "%8d ", -1);
 		sprintf(&Wfdisc_buf[25], "%9.4f ", current_channel->latitude);
  		sprintf(&Wfdisc_buf[35], "%9.4f ", current_channel->longitude);
  		sprintf(&Wfdisc_buf[45], "%9.4f ", current_channel->elevation/1000);
   		sprintf(&Wfdisc_buf[55], "%-50.50s ", current_station->name);
 		sprintf(&Wfdisc_buf[106], "%-4s ", "-");
  		sprintf(&Wfdisc_buf[111], "%-6s ", "-");
 		sprintf(&Wfdisc_buf[118], "%9.4f ", 0.0);
  		sprintf(&Wfdisc_buf[128], "%9.4f ", 0.0);
  		sprintf(&Wfdisc_buf[138], "%-17s\n", lddate);

		sprintf (outfile_name, "rdseed.site", css_filename);
		if ((outfile = fopen (outfile_name, "a")) == NULL)
		{
			fprintf (stderr,"\tWARNING (output_css):  ");
			fprintf (stderr,"Output SITE file is not available for writing.\n");
			fprintf (stderr, "\tExecution continuing.\n");

			perror("output_css()");

			chdir(orig_dir);

			return;
		}
		

		if (fwrite (Wfdisc_buf, strlen(Wfdisc_buf), 1, outfile) != 1)
		{
			fprintf (stderr, "WARNING (output_css):  ");
			fprintf (stderr, "failed to properly write CSS SITE data to %s.\n", outfile_name);

			perror("output_css()"); 
 
			fprintf (stderr, "\tExecution continuing.\n");
		}
		fclose (outfile);

  		sprintf(&Wfdisc_buf[0], "%-6s ", data_hdr->station);
		sprintf(&Wfdisc_buf[7], "%-8s ", channel);
		sprintf(&Wfdisc_buf[16], " %04d%03d ", stime.year, stime.day);
 		sprintf(&Wfdisc_buf[25], "%8d ", -1);
  		sprintf(&Wfdisc_buf[34], "%8d ", -1);			/* off date */
  		sprintf(&Wfdisc_buf[43], "%-4s ", "n");
   		sprintf(&Wfdisc_buf[48], "%9.4f ", current_channel->local_depth);
 		sprintf(&Wfdisc_buf[58], "%6.1f ", azimuth);
  		sprintf(&Wfdisc_buf[65], "%6.1f ", dip+90.0);
 		sprintf(&Wfdisc_buf[72], "%-50s ", "-");
  		sprintf(&Wfdisc_buf[123], "%17s\n", lddate);
 
		sprintf (outfile_name, "rdseed.sitechan", css_filename);

		if ((outfile = fopen (outfile_name, "a")) == NULL)
		{
			fprintf (stderr,"\tWARNING (output_css):  ");
			fprintf (stderr,"Output SITE file is not available for writing.\n");

			perror("output_css()"); 
 
			fprintf (stderr, "\tExecution continuing.\n");
		}
		

		if (fwrite (Wfdisc_buf, strlen(Wfdisc_buf), 1, outfile) != 1)
		{
			fprintf (stderr, "WARNING (output_css):  ");
			fprintf (stderr, "failed to properly write CSS SITECHAN data to %s.\n", outfile_name);

			perror("output_css()"); 
 
			fprintf (stderr, "\tExecution continuing.\n");

		}

		fclose (outfile);

		}

		current_channel = current_channel->next;

	}	/* for channel */


	/* scan for network/station already there */
	if (!scan_affiliation("rdseed.affiliation", 
				current_station->network_code,
				current_station->station))
	{

		if ((outfile = fopen("rdseed.affiliation", "a+")) == NULL)
               	{
                       	fprintf (stderr,"\tWARNING (output_css):  ");
                       	fprintf (stderr,"Output affliation file is not available for writing.\n");

                       	perror("output_css()");

                       	fprintf (stderr, "\tExecution continuing.\n");

               	}
             
		if (outfile != NULL) 
		{
			fprintf(outfile, "%-8.8s%-6.6s%17s\n", 
					current_station->network_code,
					current_station->station,
					lddate);

			fclose(outfile);

		}

	}		/* affiliation */


	if (!scan_network("rdseed.network", current_station->network_code)) 
	{
		if ((outfile = fopen ("rdseed.network", "a+")) == NULL)
		{
                       	fprintf (stderr,"\tWARNING (output_css):  ");
                       	fprintf (stderr,"CSS network file is not available for writing.\n");

                       	perror("output_css()");

                       	fprintf (stderr, "\tExecution continuing.\n");
                }
		else
		{
              
                	fprintf(outfile, 
				"%-8.8s%-80.80s%-4.4s%-15.15s%8.8d%-17s\n",
                               	current_station->network_code,
				get_net(current_station->owner_code),
				"-1",
				"-1",
				-1,
                               	lddate);

			fclose(outfile);

		}

	}		/* network */


	/* no need to create file more than once */
	if ((access("rdseed.origin", F_OK) < 0) && (type71_head != NULL))
	{ 
		int etime;
		int netmag;
		char **jdate;
		char jul_date[10];
		struct type71sub *this_mag; 

		int n;

                if ((outfile = fopen ("rdseed.origin", "a+")) == NULL)
                {
                        fprintf (stderr,"\tWARNING (output_css):  ");
                        fprintf (stderr,"CSS origin file is not available for writing.\n");

                        perror("output_css()");

                        fprintf (stderr, "\tExecution continuing.\n");

                }
		else
		{
			struct type71 *t71_ptr = type71_head;

			while (t71_ptr)
			{
		
				n = split(t71_ptr->origin_time, &jdate, ',');

				if (n == 0)
				{
					fprintf(stderr, "Warning, output_css(): Bad hypo date encountered\n");
					strcpy(jul_date, "0001001");
				}	
				else
				{
					n == 1 ? 
					    /* no day number */
					    sprintf(jul_date, 
							"%s001", 
							jdate[0]): 
					    sprintf(jul_date, 
							"%s%03d", 
							jdate[0], 
							atoi(jdate[1]));
				}

				fuse(&jdate, n);

				timecvt(&stime, t71_ptr->origin_time);
		
				etime  = stime.second;
				etime += stime.minute  * 60;
				etime += stime.hour    * 3600;
				etime += (stime.day-1) * 3600 * 24;

				for (i = 1971; i <= stime.year; i++)
				{
					if (isaleap(i - 1)) 
						etime += 366*24*3600;
					else 
						etime += 365*24*3600;
				}

				fprintf(outfile, "%9.4f %9.4f %9.4f %17.5f %8d %8d %-8s %4d %4d %4d %8d %8d %-7s %9.4f %s",

					t71_ptr->latitude,
					t71_ptr->longitude,
					t71_ptr->depth,
					(float) etime,
					ORID,
					-1,
					jul_date,
					-1,		/* nass */
					-1,		/* ndef */
					-1,		/* ndp  */
					t71_ptr->seismic_region,
					t71_ptr->seismic_location,
					"-",		/* event type */
					-999.9, 	/* estimated phase depth */
					"-");		/* depth method used */



				for (i = 0; i < t71_ptr->number_magnitudes; i++) {
					STRUPPERCASE(t71_ptr->magnitude[i].type);
				}

				this_mag = NULL;
				for (i = 0; i < t71_ptr->number_magnitudes; i++) {
					if (strstr(t71_ptr->magnitude[i].type, "MB") != NULL)
						this_mag = &t71_ptr->magnitude[i];
				}

				if (this_mag == NULL) {
					fprintf(outfile, " %7.2f %8d ", -999.0, -1);
				} else {
					fprintf(outfile, " %7.2f %8d ", this_mag->magnitude, -1);
				}
			
				this_mag = NULL;
				for (i = 0; i < t71_ptr->number_magnitudes; i++) {
					if (strstr(t71_ptr->magnitude[i].type, "MS") != NULL)
						this_mag = &t71_ptr->magnitude[i];
				}
 
                        	if (this_mag == NULL) {
					fprintf(outfile, "%7.2f %8d ", -999.0, -1);
                        	} else {
                                	fprintf(outfile, "%7.2f %8d ", this_mag->magnitude, -1);
                        	}
       
				this_mag = NULL;
				for (i = 0; i < t71_ptr->number_magnitudes; i++) {
					if (strstr(t71_ptr->magnitude[i].type, "ML") != NULL)
						this_mag = &t71_ptr->magnitude[i];
				}

                        	if (this_mag == NULL) {
                                	fprintf(outfile, "%7.2f %8d ", -999.0, -1);
                        	} else {
                                	fprintf(outfile, "%7.2f %8d ", this_mag->magnitude, -1);
                        	}
        
				fprintf(outfile, "%-15s %-15s %8d %-17s\n", 
						"-",
						get_src_name(type71_head->source_code),
						-1,
						lddate);

				t71_ptr = t71_ptr->next;

			}	/* while more t_71s */
		} /* else */
	}

	chdir(orig_dir);

}


/**************************************************
 * int scan_affilition()
 *	helper proc for output_css()
 *
 * 	scan file for matching station/network combo.
 * 
 */

int scan_affiliation(fname, n, s)
char *fname, *s, *n;

{
	char stn[20], net[20], ld_date[20];
	FILE *f;

	if ((f = fopen (fname, "r")) == NULL)
		return 0;	/* not there, scan failed */

	while (1)
	{

				/* note: load date is 2 fields */
		if (fscanf(f, "%s %s %*s %*s\n", net, stn) != 2)
		{
			fclose(f);
			return 0;	/* end of the line - bale */
		}

		if ((strcasecmp(n, net) == 0) && (strcasecmp(s, stn) == 0))
		{
			fclose(f);
			return 1;	/* found it - bale */
		}
	}

	/* should never get here */
	return 0;
}

/*****************************************************
 * scan_network() helper proc for output_css()
 *	checks each line for existing network
 */

int scan_network(fname, n)
char *fname;
char *n;

{

	FILE *f;
        char net[20];

	char buffer[200];

	int num_flds;


        if ((f = fopen (fname, "r")) == NULL)
                return 0;       /* not there, scan failed */

        while (fgets(buffer, sizeof(buffer), f))
        {
		/* lop off at first space, only scan network code */
		sscanf(buffer, "%s", net);

                if ((strcasecmp(n, net) == 0))
                {
			fclose(f);
                        return 1;       /* found it - bale */
                }
        }

	fclose(f);
 
        return 0;

}

char *get_net(code)
int code;

{
	char *ch_ptr;

	struct type33 *t_33_ptr;

	t_33_ptr = find_type_33(type33_head, code);

	if (t_33_ptr == NULL)
	{
		return "";
	}

	return t_33_ptr->abbreviation;
	
}

