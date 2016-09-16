#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $filename_spectrum_count="";
my $filename_bed="";

if ($ARGV[0]=~/\w/) { $filename_bed=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $filename_spectrum_count=$ARGV[1];} else { $error=1; }

my $filename_bedgraph=$filename_bed;
$filename_bedgraph=~s/\.bed$//i;
$filename_bedgraph=~s/\.re$//i;

if ($error==0)
{
	open (LOG,">$filename_bedgraph.bedgraph.log");
	open (OUT_BED,">$filename_bedgraph.unique.bed");
	open (OUT_GRAPH,">$filename_bedgraph.bedgraph");
	print OUT_GRAPH qq!track type=bedGraph name="$filename_bedgraph Graph" description="$filename_bedgraph Graph" visibility=full color=200,100,0 altColor=0,100,200 priority=20\n!;
	my $line="";
	my %bed=();
	my %pep=();
	my $bed_count=0;
	my $fasta_count=0;
	my $fasta_found_count=0;
	if (open (IN,"$filename_bed"))
	{
		$line=<IN>;
		chomp($line);
		$line=~s/name="?([^\"]+)"?/name="$filename_bedgraph"/;
		$line=~s/description="?([^\"]+)"?/description="$filename_bedgraph"/;
		print OUT_BED qq!$line\n!;
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $chr=$1;
				my $start=$2;
				my $end=$3;
				$chr=~s/^chr//;
				if ($chr<10) { $chr="0$chr";}
				$bed{"$chr:$start-$end"}=$line;
			} else { print LOG qq!Error parsing: $line!; }
		}
		close(IN);
	}
	if (open (IN,"$filename_spectrum_count"))
	{
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([0-9\-\+edED\.]+)$/)
			{
				my $pep="\U$1";
				my $spectrum_count=$2;
				$pep=~s/L/I/g;
				$pep=~s/^\s*\([A-Za-z]\)\s*//;
				$pep=~s/\s*\([A-Za-z]\)\s*$//;
				$pep{$pep}=$spectrum_count;
			}
		}
		close(IN);
	}
	foreach my $key (sort keys %bed)
	{
		if ($bed{$key}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t?([^\t]*)\t?([^\t]*)/)
		{
			my $chr=$1;
			my $start=$2;
			my $end=$3;
			my $pep=$4;
			my $segments=$10;
			my $segments_len="$11,";
			my $segments_pos="$12,";
			my $pep_=$pep;
			$pep_=~s/L/I/g;
			print OUT_BED "$bed{$key}\n";
			if ($pep{$pep_}=~/\w/)
			{
				for(my $i=0;$i<$segments;$i++)
				{
					if ($segments_pos=~s/^([0-9]+)\,//)
					{
						my $start_=$start+$1;
						if ($segments_len=~s/^([0-9]+)\,//)
						{
							my $end_=$start_+$1;
							print OUT_GRAPH qq!$chr\t$start_\t$end_\t$pep{$pep_}\n!;
						} else { print LOG qq!Error: segment length not found: $bed{$key}\n!; }
					} else { print LOG qq!Error: segment position not found: $bed{$key}\n!; }
				}
			} else { print LOG qq!Error: spectrum count not found: $bed{$key}\n!; }
		}
	}
	close(OUT_BED);
	close(OUT_GRAPH);
	close(LOG);
}