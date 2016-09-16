#!/usr/local/bin/perl

$error=0;
if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $dir="."; }
if ($error==0)
{
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach $filename (@allfiles)
		{
			if ($filename=~/\.raw$/i)
			{
				print qq!$filename\n!;
				system(qq!D:\\Server\\ProteoWizard\\msconvert "$dir\\$filename" --mzXML  --filter "msLevel 2-" --filter "peakPicking true 1-"  --filter "threshold count 100 most-intense" -o "$dir"!);
			}
		}
	}
}

