#!/usr/local/bin/perl

if ($ARGV[0]=~/\w/) { $dir="$ARGV[0]";} else { $dir="."; }
if (opendir(dir,"$dir"))
{
	my @allfiles=readdir dir;
	closedir dir;
	foreach $filename (@allfiles)
	{
		if ($filename=~/\.fa$/i)
		{
			print qq!$filename\n!;
			system(qq!D:\\Program_Code\\My_Code\\Nucleotide2Aminoacid\\converter.pl "$dir/$filename"!);
		}
	}
}
