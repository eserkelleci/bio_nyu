#!c:/perl/bin/perl.exe
#

use strict;
my $filename="";
my $filename2="";

my $error=0;

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="human.protein.gpff"; } # ftp://ftp.ncbi.nlm.nih.gov/refseq/H_sapiens/mRNA_Prot/human.protein.gpff
if ($ARGV[1]=~/\w/) { $filename2=$ARGV[1];} else { $filename2="refSeqAli.txt"; } # http://hgdownload.cse.ucsc.edu/goldenPath/hg19/chromosomes/refSeqAli.txt

if ($error==0)
{
	open (OUT,">$filename.bed");
	open (LOG,">$filename.bed.log");
	my $line="";
	my %alignment_strand=();
	my %alignment_chr=();
	my %alignment_pos=();
	my %alignment_seg_len=();
	my %alignment_seg_pos=();
	if (open (IN,"$filename2"))
	{
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				$alignment_strand{$11}=$10;
				$alignment_chr{$11}=$15;
				$alignment_pos{$11}=$17;
				$alignment_seg_len{$11}="$20,";
				$alignment_seg_pos{$11}="$22,";
				#print qq!$11 $15 $17\n!;
			}
		}
	}
	if (open (IN,"$filename"))
	{
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^LOCUS/) 
			{ 
				if ($line=~/^LOCUS\s*([^\s]+)/) 
				{ 
					my $protein=$1; 
					my $gene="";
					my $mrna_name="";
					my $mrna_protein_start="";
					my $mrna_protein_end="";
					while ($line and $line!~/^\/\//)
					{
						if ($line=~/^\s*\/coded_by=\"([^\"]+)\"$/) 
						{
							my $line_=$1;
							if ($line_=~s/^\s*complement\((.*)\)\s*$/$1/) { print qq!$line\n!;}
							if ($line_=~/^([^\:]+):([0-9]+)\.\.([0-9]+)$/) 
							{ 
								$mrna_name=$1; 
								$mrna_protein_start=$2; 
								$mrna_protein_end=$3; 
								$mrna_name=~s/\..*$//;
							}
						}
						if ($line=~/^\s*\/gene=\"([^\"]+)\"$/) 
						{ 
							$gene=$1; 
						}
						$line=<IN>;
					}
					if ($mrna_name=~/\w/ and $mrna_protein_start=~/\w/ and $mrna_protein_end=~/\w/) 
					{
						if ($alignment_chr{$mrna_name}=~/\w/)
						{
							if ($alignment_strand{$mrna_name}=~/\-/)
							{
								my $len_sum=0;
								my $temp=$alignment_seg_len{$mrna_name};
								while($temp=~s/^([^\,]+)\,//)
								{
									my $len=$1;
									$len_sum+=$len;
								}
								my $temp_=$mrna_protein_start;
								$mrna_protein_start=$len_sum-$mrna_protein_end+1;
								$mrna_protein_end=$len_sum-$temp_+1;
							}
							my $started=0;
							my $last=0;
							my $len_sum=0;
							my @exon_len=();
							my @exon_pos=();
							my $exon_num=0;
							my $min=0;
							my $max=0;
							my $temp=$alignment_seg_len{$mrna_name};
							my $temp_=$alignment_seg_pos{$mrna_name};
							while($temp=~s/^([^\,]+)\,//)
							{
								my $len=$1;
								if ($temp_=~s/^([^\,]+)\,//)
								{
									my $pos=$1;
									$len_sum+=$len;
									if ($mrna_protein_start<$len_sum and $started==0)
									{
										$started=1;
										$pos+=$len-($len_sum-$mrna_protein_start)-1;
										$min=$pos;
										$len=$len_sum-$mrna_protein_start+1;
									}
									if ($mrna_protein_end<$len_sum and $started==1)
									{
										$last=1;
										$len=$mrna_protein_end-($len_sum-$len);
										$max=$pos+$len;
									}
									if ($started==1)
									{
										
										$exon_len[$exon_num]=$len;
										$exon_pos[$exon_num]=$pos-$min;
										$exon_num++;
									}
									if ($last==1) { $started=0; }
								} else { print LOG qq!Error parsing position\n! }
							}
							print OUT qq!$alignment_chr{$mrna_name}\t$min\t$max\t$gene-$mrna_name-$protein\t1000\t$alignment_strand{$mrna_name}\t$min\t$max\t0\t$exon_num!;
							print OUT qq!\t!;
							for(my $i=0; $i<$exon_num;$i++) { if ($i>0) { print OUT ","; } print OUT "$exon_len[$i]"; }
							print OUT qq!\t!;
							for(my $i=0; $i<$exon_num;$i++) { if ($i>0) { print OUT ","; } print OUT "$exon_pos[$i]"; }
							print OUT qq!\n!;
						} else { print LOG qq!Error finding alinment: $protein $mrna_name\n! }
					} else { print LOG qq!Error finding mRNA: $protein\n! }
				} else { print LOG qq!Error finding protein name: $line\n! }
			}
			else
			{
				$line=<IN>;
			}
		}
		close(IN);	
	}
}