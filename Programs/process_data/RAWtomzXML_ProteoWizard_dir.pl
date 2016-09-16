#!/usr/local/bin/perl

use strict;

my $error=0;
my $dir="";
if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $dir="."; }

if ($error==0)
{
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/\.RAW$/i)
			{
				#print qq!$filename\n!;
				system(qq!D:\\Server\\ProteoWizard\\msconvert "$dir/$filename" --mzXML  --filter "msLevel 2-" --filter "peakPicking true 1-"  --filter "threshold count 100 most-intense"!);
			}
		}
	}
}