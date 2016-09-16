#!c:/perl/bin/perl.exe
# This program groups similar proteins and gets one representative for the group ( similarity in this means same protein sequence )
#
use strict;

my $error=0;
my $dir0="";
my $filename="";
my $line="";
my %proteins=();
my $proteins="";
my $protein_name="";
if ($ARGV[0]=~/\w/) { $dir0=$ARGV[0];} else { $dir0="."; }
if ($error==0)
{
	if (opendir(dir,"$dir0"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach $filename (@allfiles)
		{
			if ($filename=~/\.output\.fasta$/i)
			{
				print qq!$filename\n!;
				open (IN,qq!$dir0/$filename!) || die "Could not open $filename\n";
				while ($line=<IN>)
				{
					if ($line=~/^\>(.*)/)
					{
						$protein_name=$1;
					}
					elsif($line=~/^([A-Z\s]+)/)
					{
						$proteins=$1;
						$proteins{$proteins}=$protein_name;
					}
				}
				close(IN);
			}
		}
	}
	open(OUT,qq!>$dir0/grouped_proteins.fasta!);
	foreach my $prots(keys %proteins)
	{
		print OUT qq!>$proteins{$prots}\n$prots!;
	}
	close(OUT);
}