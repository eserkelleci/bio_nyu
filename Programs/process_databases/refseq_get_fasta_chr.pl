#!c:/perl/bin/perl.exe

use strict;

my $error=0;
my $dir="";
my $chr_filter="";
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; } 
if ($ARGV[1]=~/\w/) { $chr_filter=$ARGV[1];} else { $chr_filter="8"; } 

if ($error==0)
{
	if (open (OUT,">$dir-refseq_$chr_filter.fasta"))
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
					my $name="";
					my $description="";
					my $seq="";
					my $version="";
					my $gi="";
					my $gene="";
					my $chr="";
					my $line="";
					my $count=0;
					my $count_selected=0;
					while($line=<IN>)
					{
						if ($line=~/^LOCUS\s+(\S+)/)
						{
							$locus=$1;
							$name="";
							$description="";
							$seq="";
							$version="";
							$gi="";
							$gene="";
							$chr="";
						}
						if ($line=~/^DEFINITION/)
						{
							my $done=0;
							$line=~s/^DEFINITION//;
							while($done==0)
							{
								chomp($line);
								if ($line=~/^\s/) 
								{
									$line=~s/^\s+//;
									$line=~s/\s+$//;
									$description.="$line ";
									$line=<IN>;
								}
								else { $done=1; }
							}
						}
						if ($line=~/^VERSION\s+([\S\.]+)\s+GI:([0-9]+)/)
						{
							$version=$1;
							$gi=$2;
							$name="gi\|$gi\|ref\|$version\|";
						}
						if ($line=~/^\s*\/chromosome=\"([A-Za-z0-9]+)\"/)
						{
							$chr=$1;
						}
						if ($line=~/^ORIGIN/)
						{
							my $done=0;
							$line=<IN>;
							while($done==0)
							{
								chomp($line);
								if ($line=~/^\s/) 
								{
									$line=~s/^\s+[0-9]+\s+//;
									$line=~s/\s//g;
									$seq.=uc("$line\n");
									$line=<IN>;
								}
								else { $done=1; }
							}
						}
						if ($line=~/^\/\//)
						{
							if ($chr=~/^$chr_filter$/)
							{
								print OUT qq!>$name GN=$gene CHR=$chr $description\n$seq!;
								$count_selected++;
							}
							$count++;
							$locus="";
						}
						if ($line=~/^\s*\/gene=\"?([^\"]+)\"?/)
						{
							$gene=$1;
						}
					}
					close(IN);
					print qq!$count_selected sequences selected out of $count\n!;
				}
			}
		}
		close(OUT);
	}
}

