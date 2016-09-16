#!/usr/local/bin/perl

use strict;

my $error=0;
my $dir="";
my $mslevel="";
my $type="";
if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $mslevel="$ARGV[1]";} else { $mslevel="2"; }
if ($ARGV[2]=~/\w/) { $type="$ARGV[2]";} else { $type="CID"; }

if ($error==0)
{
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/\.mzXML$/i)
			{
				print qq!$filename\n!;
				system(qq!D:\\Programs\\process_data\\mzXMLtoMGF "$dir\\$filename" $mslevel $type!);
			}
		}
	}
}

