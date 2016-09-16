#!c:/perl/bin/perl.exe
#

use strict;
my $filename="";

my $error=0;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $error=1; }

if ($error==0)
{
	open (OUT,">$filename.bed");
	open (LOG,">$filename.ensembl_gtf_to_bed.log");
	my $line="";
	my %loc=();
	my %gene=();
	if (open (IN,"$filename"))
	{
		while ($line=<IN>)
		{
			chomp($line);
			
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/)
			{
				my $chr=$1;
				my $source=$2;
				my $feature=$3;
				my $start=$4;
				my $end=$5;
				my $score=$6;
				my $strand=$7;
				my $frame=$8;
				my $attribute=$9;
				if ($chr=~/^\s*[0-9XY]+$\s*/ and $source=~/^\s*protein_coding\s*$/ and $feature=~/^\s*CDS\s*/)
				{
					if ($attribute=~/protein_id\s*\"([^\"]+)\"\s*;/)
					{
						my $protein=$1;
						if ($attribute=~/gene_name\s*\"([^\"]+)\"\s*;/)
						{
							my $gene=$1;
							$gene{$protein}=$gene;
							$loc{$protein}.="#$chr$strand:$start-$end#";
						} else { print LOG qq!Gene not found: $line\n!; }
					} else { print LOG qq!Protein not found: $line\n!; }
				}
			}
		}
		close(IN);
		foreach my $protein (sort keys %loc)
		{
			my $chr="";
			my $strand="";
			my $chr_same=1;
			my $strand_same=1;
			my $exon_num=0;
			my $min=100000000000;
			my $max=0;
			my @exon_pos=();
			my @exon_length=();
			my $temp=$loc{$protein};
			while($temp=~s/^#([^#]+)#//)
			{
				my $temp_=$1;
				if ($temp_=~/^([0-9XY]+)([\+\-])\:([0-9]+)\-([0-9]+)$/)
				{
					my $chr_=$1;
					my $strand_=$2;
					my $start=$3;
					my $end=$4;
					if ($min>$start) { $min=$start; }
					if ($max<$start) { $max=$start; }
					if ($min>$end) { $min=$end; }
					if ($max<$end) { $max=$end; }
					if ($chr!~/\w/) { $chr=$chr_; } else { if ($chr!~/^$chr_$/) { $chr_same=0; } }
					if ($strand!~/\w/) { $strand=$strand_; }  else { if ($strand!~/^$strand_$/) { $strand_same=0; } }
				} else { print LOG qq!Error parsing location: $protein: $temp_\n!; }
			}
			if ($chr_same==0 or $strand_same==0)
			{
				print LOG qq!Error: $loc{$protein} $chr_same $strand_same\n!;
			}
			else
			{
				my $temp=$loc{$protein};
				if ($strand=~/\+/)
				{
					while($temp=~s/^#([^#]+)#//)
					{
						my $temp_=$1;
						if ($temp_=~/^([0-9XY]+)([\+\-])\:([0-9]+)\-([0-9]+)$/)
						{
							my $start=$3;
							my $end=$4;
							if ($temp!~/\w/) { $end+=3; }
							$exon_pos[$exon_num]=$start-$min;
							$exon_length[$exon_num]=$end-$start+1;
							$exon_num++;
						}
					}
					$min--;
					$max+=3;
				}
				else
				{
					$min-=4;
					while($temp=~s/#([^#]+)#$//)
					{
						my $temp_=$1;
						if ($temp_=~/^([0-9XY]+)([\+\-])\:([0-9]+)\-([0-9]+)$/)
						{
							my $start=$3;
							my $end=$4;
							if ($exon_num==0) { $start-=4; } else { $start--; }
							$end--;
							$exon_pos[$exon_num]=$start-$min;
							$exon_length[$exon_num]=$end-$start+1;
							$exon_num++;
						}
					}
				}
				#print qq!$loc{$protein} $chr_same $strand_same\n!;
				print OUT qq!chr$chr\t$min\t$max\t$gene{$protein}-$protein\t1000\t$strand\t$min\t$max\t0\t$exon_num!;
				print OUT qq!\t!;
				for(my $i=0; $i<$exon_num;$i++) { if ($i>0) { print OUT ","; } print OUT "$exon_length[$i]"; }
				print OUT qq!\t!;
				for(my $i=0; $i<$exon_num;$i++) { if ($i>0) { print OUT ","; } print OUT "$exon_pos[$i]"; }
				print OUT qq!\n!;
			}
		}
	}
}