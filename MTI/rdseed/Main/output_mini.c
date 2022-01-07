/*===========================================================================*/
/* SEED reader     |            output_mini                |    subprocedure */
/*===========================================================================*/
/*
				
	Problems:	none known
	Language:	C, hopefully ANSI standard
	Author:		Chris Laughbon	
	Revisions:	01/26/96 added D Newhouser's corrections for geoscope
*/

#include "rdseed.h"			/* SEED tables and structures */
#include <stdio.h>
#include <sys/errno.h>
#include <sys/stat.h>
#include <sys/param.h>


#define TIME_PRECISION 10000		/* number of divisions in a */
#define LONG long
#define ULONG long

#define BOOL int

static int seed_data_record[5000];

static int c = 0;

/* Globally defines as process_data() fills it up. */
struct mini_data_hdr mini_data_hdr;

char strlst();
char *scan_for_eob();
char *scan_for_blk_1000();
char *get_event_dir_name();


extern int EventDirFlag;
 

struct type50 *get_station_rec();

/* ---------------------------------------------------------------------- */
void output_mini(data_hdr, offset)
struct data_hdr *data_hdr;
int offset;
{
	FILE *outfile;				/* output file pointer */
	char outfile_name[100], channel[10];	/* output file name */
	int i, j,k;				/* counter */

	int lrecl;

	int num_records;			/* number of Steims records */
	struct
	{
		char   SequenceNumber[6] ;
		char   Data_header_indicator ;
		char   Reserved_bytes_A ;
		struct input_data_hdr hdr;	/* fixed section of header */
	} fsdh;

	struct data_blk_1000 d_blk_1000;

	double dip, azimuth;		/* Temp place for these values */
	char *p;
	double duration;
	struct time newtime;
	struct type52 *old_channel;
	char orig_dir[MAXPATHLEN];

	old_channel = current_channel;

	getcwd(orig_dir, MAXPATHLEN);

	chdir(output_dir);

	sprintf(outfile_name, "mini.seed");

	if ((outfile = fopen(outfile_name, "a")) == NULL)
	{
		fprintf (stderr, "\tWARNING (output_mini):  ");
		fprintf (stderr, 
			"Output file: %s is not available for writing.\n",
			outfile_name);

		perror("output_mini");

		fprintf (stderr, "\tExecution continuing.\n");

		chdir(orig_dir);

		return;
	}


	for (k=0;k<data_hdr->num_mux_chan;k++)
	{
		if (current_channel == NULL)
		{
			fprintf(stderr, "\tERROR - Unexpected End of Multiplexed Channel List\n");
		
			chdir(orig_dir);

			return;
		}


		for (i=0;i<10;i++) 
			channel[i] = 0;

		strcpy(channel,current_channel->channel);

		if (data_hdr->num_mux_chan > 1)
		{
                	int i;
                	for (i=0; i<3; i++) 
			{
                        	if (channel[i] == ' ' || 
				    channel[i] == '\0') 
					break;
                	}
                	if (i > 2) 
				i = 2;

                	channel[i] = data_hdr->mux_chan_name[k];
        	}


		/* make sure the mini_data_hdr has the right 
		 * channel orientation code. If geoscope, it
		 * will be missing 
		 */
		memcpy(mini_data_hdr.hdr.channel, channel, 3);
 
/*                 +=======================================+                 */
/*=================|          Build the SAC header         |=================*/
/*                 +=======================================+                 */




/*                 +=======================================+                 */
/*=================|  build name for and open output file  |=================*/
/*                 +=======================================+                 */

		/* give the user some indication as to what we are doing. */ 

		printf("Appending Net:Stn:Loc:Chn %.2s:%.5s:%.2s:%.3s at %04d.%03d.%02d.%02d.%02d.%04d to mini.seed\n",
				type10.version >= 2.3 ? 	
					data_hdr->network : "N/A", 
				data_hdr->station, 
				data_hdr->location,
				channel,
            			data_hdr->time.year,
            			data_hdr->time.day,
            			data_hdr->time.hour,
            			data_hdr->time.minute,
            			data_hdr->time.second,
            			data_hdr->time.fracsec);
	
/*                 +=======================================+                 */
/*=================|        write header section           |=================*/
/*                 +=======================================+                 */

		memset((char *)&fsdh, 0, sizeof(fsdh));

		memcpy((char *)&fsdh.hdr, 
			(char *)&mini_data_hdr.hdr, sizeof(fsdh.hdr)); 

		/* update the timing info - may have changed */
		fsdh.hdr.time.year = data_hdr->time.year;
		fsdh.hdr.time.day  = data_hdr->time.day; 
		fsdh.hdr.time.hour = data_hdr->time.hour; 
		fsdh.hdr.time.minute = data_hdr->time.minute; 
		fsdh.hdr.time.second = data_hdr->time.second; 
		fsdh.hdr.time.fracsec= data_hdr->time.fracsec; 
         
		
		fsdh.Data_header_indicator = input.type;

		/* data_hdr's nsamples are accumulated over the entire time span */
		fsdh.hdr.nsamples = data_hdr->nsamples;

/*:: DSN Change */
/* Since a blockette 1000 may be added to the mini_data_hdr blockette   */
/* list, we need to update the info in the mini_data_hdr to reflect the */
/* changes.  Otherwise, if we reuse this info for multiplexed data,     */
/* the mini_data_hdr and the blockette info will not correspond.        */


		/* check for presense of the blockette 1000 */
		if (mini_data_hdr.hdr.bofb) 	
			p = scan_for_blk_1000(mini_data_hdr.blockettes, 
						((char *)&mini_data_hdr.hdr) - 8);
		else
			p = NULL;

		if (p)
		{
			/* see SEED manual for steim code */	
			((struct data_blk_1000 *)p)->encoding_fmt = 10;  

			/* find the native word order */
                        d_blk_1000.word_order =
                                get_word_order();

			/* lets make sure the number_of_blockettes >= 1 */
			if (mini_data_hdr.hdr.number_blockettes < 1)
			{
				mini_data_hdr.hdr.number_blockettes = 1;
			}

		}
		else
		{
			/* now scan for end of blocks */
			if (mini_data_hdr.hdr.bofb)
				p = scan_for_eob(mini_data_hdr.blockettes, 
						 mini_data_hdr.hdr.bofb);
			else 
				p = mini_data_hdr.blockettes;

			if (p == (char *)NULL)
			{
				fprintf(stderr, "output_mini: unable to add blockette 1000\n");
				fprintf(stderr, "output_mini: unable to continue\n");
			
				chdir(orig_dir);

				return;
			}

			/* add one for blk 1000 */
			mini_data_hdr.hdr.number_blockettes++;  

			/* create block 1000, and tag onto end of blockettes */
			memset((char *)&d_blk_1000, 0, sizeof(d_blk_1000));

			d_blk_1000.hdr.type = 1000;
			
			/* see SEED manual for steim code */
    			d_blk_1000.encoding_fmt = 10;  

			/* the next blockette field stays at zero */

    			d_blk_1000.word_order = 
				get_word_order();

			d_blk_1000.rec_length = 12;

			/* copy to blockettes holding buffer */
			memcpy((char *)p, (char *)&d_blk_1000, sizeof(d_blk_1000));

			mini_data_hdr.hdr.bofb = 48;

			/* calculate "new" end of blocks */	
			mini_data_hdr.hdr.bod = mini_data_hdr.hdr.bofb + 
					((p + sizeof(d_blk_1000)) - mini_data_hdr.blockettes);

			/* if it overflowed the 64 byte boundary, bump it up */	
			mini_data_hdr.hdr.bod = 
			  ((int)((mini_data_hdr.hdr.bod / 65)) + 1) * 64;


		}		/* else block 1000 not there */

		 
                /* update the start of data - first 64 byte boundary
                 * after any and all data blockettes
                 */
                fsdh.hdr.bofb = mini_data_hdr.hdr.bofb;
                fsdh.hdr.bod = mini_data_hdr.hdr.bod;
                fsdh.hdr.number_blockettes =
                        mini_data_hdr.hdr.number_blockettes;

		/* write the Steim Compressed data */

		lrecl = (2 << (((struct data_blk_1000 *)p)->rec_length - 1));
 
		if (data_hdr->nsamples == 0)
		{
			/* maybe blk 201 or other */

			memset(seed_data_record, ' ', sizeof(seed_data_record));

			fwrite(&fsdh, fsdh.hdr.bofb, 1, outfile);

			fwrite(&mini_data_hdr.blockettes, 
					fsdh.hdr.bod - fsdh.hdr.bofb, 1, outfile);

			/* fill up the logical record */
		
			fwrite(seed_data_record, 
				lrecl - sizeof(fsdh) - (fsdh.hdr.bod - fsdh.hdr.bofb), 
				1, outfile);
			
		}
		else
		{

			j = k*(seis_buffer_length/data_hdr->num_mux_chan);

			num_records= 
				Steim_comp(outfile, &seismic_data[offset+j],
					&fsdh, 
					data_hdr->nsamples, 	
					lrecl, 
					seed_data_record,
					fsdh.hdr.number_blockettes, 
					fsdh.hdr.bod - fsdh.hdr.bofb, 
					mini_data_hdr.blockettes, 
					0, 0, NULL);

			if (num_records == -1)
			{
				fprintf (stderr, "\tWARNING (output_steim):  ");
				fprintf (stderr, "failed to properly write Steim data to %s.\n",
							outfile_name);

				perror("output_mini()");

				fprintf (stderr, "\tExecution continuing.\n");
			}

			current_channel = current_channel->next;

		}

	}		/* end of big for loop (for k) */

	fclose(outfile);

	chdir(orig_dir);

	return;

}				/* output_mini */

/* ------------------------------------------------------------------------ */
void blockette_swap(b_ptr, base)
struct data_blk_hdr *b_ptr;
char *base;


{
	short type, next_blk_byte;

	while (1)
    	{
		b_ptr->type = swap_2byte(b_ptr->type);

                b_ptr->next_blk_byte = swap_2byte(b_ptr->next_blk_byte);
			
		switch (b_ptr->type)
		{
                	case 100 :
				{
				char *p;
				float s_rate;
				
				/* must switch the sample rate - float */
                                p = (char *)&((struct data_blk_100 *)b_ptr)->sample_rate;
 
                                *((int *)&s_rate)=swap_4byte(*((int *)p));

				((struct data_blk_100 *)b_ptr)->sample_rate =
					s_rate;

				}

				break;

				
                	case 201:
                	case 300:
                	case 310:
                	case 200:
                	case 320:
                	case 390:
                	case 395:
                	case 400:
                	case 405:
				break;
			case 1000:
			case 1001:

				break;
                	default : /* oh, oh */
         
                    		fprintf(stderr, 
"blockette swapper: Bad blockette scanned\n Blockette = %d\n", b_ptr->type);
                    	
				return;

		}		/* switch */
	
        	if (b_ptr->next_blk_byte == 0)
			return;

		b_ptr = (struct data_blk_hdr *)(base + b_ptr->next_blk_byte);
 
    	}   /* while */

}

/* ------------------------------------------------------------------------ */

char *scan_for_blk_1000(b_ptr, base)
struct data_blk_hdr *b_ptr;
char *base;		/* start of the logical rec */

{

	while (1)
    	{
		if (b_ptr->type == 1000)
			/* eureka, we've found it */
			return (char *)b_ptr;
 
        	if (b_ptr->next_blk_byte == 0)
			return (char *) NULL;

		/* garbage check */
		switch (b_ptr->type)
		{
                	case 100 :
                	case 201:
                	case 300:
                	case 310:
                	case 200:
                	case 320:
                	case 390:
                	case 395:
                	case 400:
                	case 405:
                	case 1001:
				break;
                	default : /* oh, oh */
         
                    		fprintf(stderr, 
"scan_for_blk_1000(): Bad blockette scanned\n Blockette = %d\n", b_ptr->type);
                    	
				return (char *) 0;

		}		/* switch */
	
		b_ptr = (struct data_blk_hdr *)(base + b_ptr->next_blk_byte);
 
    	}   /* while */

	/* Should never get here */ 
	return (char *) 0;
 
}

/* ----------------------------------------------------------------------- */
/* ------------------------------------------------------------------------ */
char *scan_for_eob(b_ptr, position)
struct data_blk_hdr *b_ptr;
int position;

{
	int count = 0;

	BOOL finished = FALSE;

	while (!finished)
	{

		count++;

        	if (b_ptr->next_blk_byte == 0)
            		finished = TRUE;
 
            	switch (b_ptr->type)
            	{
 
                /* if finished...then update the next block field so it
                 * points to where the new block 1000 will go.
		 * position is current position from start of data record,
		 * plus the sizeof the blockette just scanned
                 */
                	case 100 :
                    		if (finished)
					/* update next block field */
					b_ptr->next_blk_byte = position + 12;
 
				b_ptr = (struct data_blk_hdr *)((char *)b_ptr + 12);
				position += 12;

                    		break;
                	case 201:
                    		if (finished)
					/* update next block field */
                        		b_ptr->next_blk_byte = position + 36;
 
                    		b_ptr = (struct data_blk_hdr *)((char *)b_ptr + 36);
				position += 36;

                    		break;
                	case 300:
                	case 310:
                    		if (finished)
					/* update next block field */
                        		b_ptr->next_blk_byte = position + 32;

                    		b_ptr = (struct data_blk_hdr *)((char *)b_ptr + 32);
				position += 32;

                    		break;

                	case 200:
                	case 320:
                	case 390:
                    		if (finished)
					/* update next block field */
                        		b_ptr->next_blk_byte = position + 28;

                    		b_ptr = (struct data_blk_hdr *)((char *)b_ptr + 28);
				position += 28;

                    		break;
                	case 395:
                	case 400:
                    		if (finished)
					/* update next block field */
                        		b_ptr->next_blk_byte = position + 16;

                    		b_ptr = (struct data_blk_hdr *)((char *)b_ptr + 16);
				position += 16;

				break;

                	case 405:
                    		if (finished)
					/* update next block field */
                        		b_ptr->next_blk_byte = position + 6;

                    		b_ptr = (struct data_blk_hdr *)((char *)b_ptr + 6);
				position += 6;

                    		break;

			case 1000:
				fprintf(stderr, "output mini seed: Found unexpected blockette 1000! Output maybe incorrect.\n"); 

                    		return (char *) 0;
	
			case 1001:
				break;

                	default : /* oh, oh */
         
fprintf(stderr, "scan_for_eob(): Bad blockette scanned\n Blockette = %d\n", b_ptr->type);
                    		return (char *) 0;
 

            	}       /* switch */
 
	}   /* while */

	/* Kludge alert: sometime the data header has the wrong count for
	 * number of blockettes that follow. So make consistent here 
	 */

	mini_data_hdr.hdr.number_blockettes = count;
 
	return (char *)b_ptr;
 
}

/* ------------------------------------------------------------------------ */

char *code_to_english(fmt)
char fmt;

{
	switch (fmt)
	{
		case 0: return("");

		case 1 :
			return("16-bit");
		case 2 :
			return("");
		case 3:
			return("32-bit");
        	case 4 :
        	case 5: 
			return ("SUN I");
        	case 10: 
			return("STEIM");
        	case 11:
			return("STEIM2");
		case 12:
        	case 13: 
        	case 14: 
		/* need to find a way to differentiate btw 24, 16, etc */
			return("GEOSCOPE");
            		break; 
        	case 15:
			fprintf(stderr, "Unable to support blockette 1000 data type! Found code = %d\n", fmt);

            		return "";
        	case 16: 
			return("CDSN");
        	case 17: 
			return("GRAEF");
        	case 18:
			fprintf(stderr, "Unable to support blockette 1000 data type! Found code = %d\n", fmt);
 
            		return "";
        	case 30:
			return("SRO G");
        	case 31: 
			fprintf(stderr, "Unable to support blockette 1000 data type! Found code = %d\n", fmt);  
 
            		return ""; 
  
        	case 32:
			return("DWWSS");
        	case 33: 
			return("RSTN");

		default:
			fprintf(stderr, "Unable to support blockette 1000 data type! Found code = %d\n", fmt);
 
                        return "";

	}

	return "";

}

/* ------------------------------------------------------------------------ */
