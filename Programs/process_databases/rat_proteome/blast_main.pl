#!/usr/local/bin/perl
# This program calls blast and executes it for the files in the mentioned folder.
#
use strict;

my $dir_file="";
my $dir_db="";
my $dir_poutput="";
my $dir_noutput="";

if ($ARGV[0]=~/\w/) { $dir_file="$ARGV[0]";} else { $dir_file="."; }
if ($ARGV[1]=~/\w/) { $dir_db="$ARGV[1]";} else { $dir_db="."; }
if ($ARGV[2]=~/\w/) { $dir_poutput="$ARGV[2]";} else { $dir_poutput="."; }
if ($ARGV[3]=~/\w/) { $dir_noutput="$ARGV[3]";} else { $dir_noutput="."; }
if (opendir(dir,"$dir_file"))
{
	my @allfiles=readdir dir;
	closedir dir; 
	foreach my $filename (@allfiles)
	{
		if ($filename=~/\.fasta$/i)
		{
			print qq!$filename\n!; 
			system(qq!D:\\Server\\blast\\ncbi-blast-2.2.25+\\bin\\tblastn.exe -query $dir_file/$filename -db $dir_db/ratgenome.fasta -out $dir_noutput/$filename.txt!);
			system(qq!D:\\Server\\blast\\ncbi-blast-2.2.25+\\bin\\blastp.exe -query $dir_file/$filename -db $dir_db/Rattus_norvegicus.RGSC3.4.64.pep.all.fasta -out $dir_poutput/$filename.txt!);
		}
	}
}