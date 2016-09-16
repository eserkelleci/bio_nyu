#!c:/perl/bin/perl.exe
#

use strict;
my $dir="";
my $filename="";

my $error=0;

if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $filename=$ARGV[1];} else { $error=1; }

if ($error==0)
{
	open (OUT,">$dir-proteins.bed");
	open (LOG,">$dir-proteins.bed.log");
	my $line="";
	my %loc=();
	my %gene=();
	my %mrna=();
	my %alignment_chr=();
	my %alignment_pos=();
	my $mrna_name="";
	my $mrna_pos="";
	my $chromosme="";
	if (open (IN,"$filename"))
	{
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t/)
			{
				$alignment_chr{$11}=$15;
				$alignment_pos{$11}=$17;
				#print qq!$11 $15 $17\n!;
			}
		}
	}
	
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename_ (@allfiles)
		{
			if ($filename_ =~ /\.gbk$/i)
			{
				if (open (IN,"$dir/$filename_"))
				{
					$line="Start";
					while ($line)
					{
						chomp($line);
						if ($line=~/^\s*\/chromosome=\"([^\"]+)\"$/) { $chromosme=$1; }
						if ($line=~/^     gene\s*(.*$)/)
						{
							$mrna_name="";
							$mrna_pos="";
						}
						if ($line=~/^     mRNA\s*(.*$)/)
						{
							$mrna_pos=$1;
							$line=" ";
							$mrna_pos=~s/^complement\((.*)\)?$/$1/;
							$mrna_pos=~s/^join\((.*)\)?$/$1/;
							$mrna_pos=~s/\.\..*$//;
							$mrna_name="";
							while ($line!~/^     [A-Za-z]/)
							{
								if ($line=~/^\s*\/transcript_id=\"([^\"]+)\"$/) { $mrna_name=$1; }
								$line=<IN>;
								chomp($line);
							}
						}
						if ($line=~/^     CDS\s*(.*$)/)
						{
							my $loc=$1;
							#print qq!$line\n!;
							my $loc_done=0;
							$line=" ";
							my $protein="";
							my $gene="";
							while ($line!~/^     [A-Za-z]/)
							{
								if ($line=~/^\s*\//) { $loc_done=1; }
								if ($loc_done==0) { if ($line=~/^\s*(.*)$/) { $loc.=$1; } }
								else
								{
									if ($line=~/^\s*\/protein_id=\"([^\"]+)\"$/) { $protein=$1; }
									if ($line=~/^\s*\/gene=\"([^\"]+)\"$/) { $gene=$1; }
								}
								$line=<IN>;
								chomp($line);
							}
							if ($mrna_name=~/\w/)
							{
								my $mrna_name_=$mrna_name;
								$mrna_name_=~s/\..*$//;
								if ($alignment_pos{$mrna_name_}=~/\w/)
								{
									$gene{$protein}=$gene;
									$mrna{$protein}="$mrna_name_:$mrna_pos:$alignment_pos{$mrna_name_}";
									$loc=~s/\s+//g;
									my $strand="+";
									if ($loc=~s/^complement\((.*)\)$/$1/) {  $strand="-"; }
									if ($loc=~/^join\((.*)\)$/)
									{
										my $loc_="$1,";
										while ($loc_=~s/^([0-9]+)\.\.([0-9]+)\,//)
										{
											my $start=$1-$mrna_pos+$alignment_pos{$mrna_name_};
											my $end=$2-$mrna_pos+$alignment_pos{$mrna_name_};
											$loc{$protein}.="#$chromosme$strand:$start-$end#";
										}
									}
								} else { print LOG qq!Error: Alignment not found: $gene{$protein}-$mrna_name:$mrna_pos-$protein\n!; }
							} else { print LOG qq!Error: Transcript not found: $gene{$protein}-$protein\n!; }
						}
						else
						{
							$line=<IN>;
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
						if ($temp=~/^#([^#]+)#/)
						{
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
								} else { print LOG qq!Error parsing location: $gene{$protein}-$protein: $temp_\n!; }
							}
							if ($chr_same==0 or $strand_same==0)
							{
								print LOG qq!Error: $gene{$protein}-$protein $loc{$protein} $chr_same $strand_same\n!;
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
											$exon_pos[$exon_num]=$start-$min;
											$exon_length[$exon_num]=$end-$start+1;
											$exon_num++;
										}
									}
									$max++;
								}
								else
								{
									while($temp=~s/^#([^#]+)#//)
									{
										my $temp_=$1;
										if ($temp_=~/^([0-9XY]+)([\+\-])\:([0-9]+)\-([0-9]+)$/)
										{
											my $start=$3;
											my $end=$4;
											$exon_pos[$exon_num]=$start-$min;
											$exon_length[$exon_num]=$end-$start+1;
											$exon_num++;
										}
									}
									$max++;
								}
								#print qq!$loc{$protein} $chr_same $strand_same\n!;
								print OUT qq!chr$chr\t$min\t$max\t$gene{$protein}-$mrna{$protein}-$protein\t1000\t$strand\t$min\t$max\t0\t$exon_num!;
								print OUT qq!\t!;
								for(my $i=0; $i<$exon_num;$i++) { if ($i>0) { print OUT ","; } print OUT "$exon_length[$i]"; }
								print OUT qq!\t!;
								for(my $i=0; $i<$exon_num;$i++) { if ($i>0) { print OUT ","; } print OUT "$exon_pos[$i]"; }
								print OUT qq!\n!;
							}			
						} else { print LOG qq!Error: $gene{$protein}-$protein: $loc{$protein}\n!; }
					}
				}
			}
		}
	}
}