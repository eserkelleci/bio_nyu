#!c:/perl/bin/perl.exe

use strict;

my $error=0;
my $filename="";
my $genes="";
if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; } 
if ($ARGV[1]=~/\w/) { $genes=$ARGV[1];} else { $genes="refseq_genes.txt"; } 
my $line="";
my %genes=();

if ($error==0)
{
	if (open (IN,qq!$genes!))
	{
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/)
			{
				$genes{$3}=$4;
				#print qq!#$3#$4#\n!;
			}
		}
		close(IN);
	}
	if (open (IN,qq!$filename!))
	{
		if (open (OUT,">$filename-genes.fasta"))
		{
			while ($line=<IN>)
			{
				chomp($line);
				if ($line=~/^\>(\S+)(.*)/)
				{
					my $name=$1; 
					my $description=$2;
					#print qq!#$name#\n!;
					if ($name=~/^gi\|([0-9]+)/)
					{
						my $gi=$1;
						#print qq!####$gi#\n!;
						if ($genes{$gi}=~/\w/) 
						{ 
							if ($description!~s/(\[[^\]]+\])$/ GN=$genes{$gi} $1/)
							{
								$description.="GN=$genes{$gi}"; 
							}
						} else { print qq!Error: gene not found: $line\n!; }
					} else { print qq!Error: gi not found: $line\n!; }
					print OUT qq!>$name $description\n!;
				}
				else
				{
					print OUT qq!$line\n!;
				}
			}
			close(IN);
		}
		close(OUT);
	}
}
