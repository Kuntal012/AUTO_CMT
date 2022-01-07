/*===========================================================================*/
/* SEED reader     |             free_type11               |   volume header */
/*===========================================================================*/
/*
	Name:		free_type11
*/
#include "rdseed.h"

void free_type11 ()
{
	int i;
	

	for (i = 0; i < type11.number_stations; i++)
	{
		free(type11.station[i].station_id);
		type11.station[i].station_id = NULL;
	}
	if (type11.station != NULL) free((char *)type11.station);
	type11.station = NULL;
	type11.number_stations = 0;

}
