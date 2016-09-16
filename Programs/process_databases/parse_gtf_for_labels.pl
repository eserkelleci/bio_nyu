#!/usr/local/bin/perl

#parse gtf file in the database for protein-gene labeling

use strict;
my $gtffile="";
my $error=0;
my $line="";
my %gene_prot=();

if ($ARGV[0]=~/\w/) { $gtffile=$ARGV[0];} else {$error=1;}
if($error==0)
{
	open(IN,qq!$gtffile!) ||  die "could not open $gtffile";
	my $labelfile=$gtffile."\-label.txt"; 
	open(OUT,qq!>$labelfile!) ||  die "could not open label file";
	while($line=<IN>)
	{
		if($line=~/gene_name "([^\"]+)"\;.*protein_id "([^\"]+)";/)
		{
			my $gene_name=$1;
			my $protein_id=$2;
			if($gene_prot{$protein_id}!~/\w/) 
			{ 
				$gene_prot{$protein_id}=$gene_name;
				print OUT qq!$gene_name\t$protein_id\n!; 
			}
		}
	}
	close(IN);
	close(OUT);
}
else
{
	print qq!no file name mentioned!;
}


