#!c:/perl/bin/perl.exe

use strict;

my $error=0;
my $dir="";
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; } 

if ($error==0)
{
	if (open (OUT,">$dir-refseq_genes.txt"))
	{
		opendir(DIR,"$dir");
		my @files = readdir DIR;
		closedir DIR;
		foreach my $filename (@files)
		{
			if ($filename=~/\.gpff$/i)
			{
				if (open (IN,"$dir/$filename"))
				{
					my $locus="";
					my $version="";
					my $gi="";
					my $chr="";
					my $line="";
					while($line=<IN>)
					{
						if ($line=~/^LOCUS\s+(\S+)/)
						{
							$locus=$1;
							$version="";
							$gi="";
							$chr="";
						}
						if ($line=~/^VERSION\s+([\S\.]+)\s+GI:([0-9]+)/)
						{
							$version=$1;
							$gi=$2;
						}
						if ($line=~/^\s*\/chromosome=\"([A-Za-z0-9]+)\"/)
						{
							$chr=$1;
						}
						if ($line=~/^\/\//)
						{
							$locus="";
						}
						if ($line=~/^\s*\/gene=\"?([^\"]+)\"?/)
						{
							my $gene=$1;
							if ($locus=~/\w/)
							{
								print OUT qq!$locus\t$version\t$gi\t$gene\t$chr\n!;
							}
						}
					}
					close(IN);
				}
			}
		}
		close(OUT);
	}
}

