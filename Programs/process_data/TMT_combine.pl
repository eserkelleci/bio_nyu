#!/usr/local/bin/perl

use strict;

my $error=0;
my $dir="";
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; } 

$dir=~s/\\/\//g;
my $line="";
my %what=();
my %quant=();
my %quant_norm=();
my %quant_prot=();
my %quant_norm_prot=();
my %prot=();
my %protein_peptides_count=();
my %protein_peptides=();
my %descriptions=();
my %codes=();

if ($error==0)
{	
	if(open (IN, qq!codes.txt!))
	{
		$line = <IN>;
		while($line = <IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)/)
			{
				$codes{$1}=$2;
				#print qq!$1 $2\n!;
			}
		}
		close(IN);
	}
	if(open (IN, qq!ensembl_descriptions.txt!))
	{
		while($line = <IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)/)
			{
				$descriptions{$1}=$2;
			}
		}
		close(IN);
	}
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/^[^\-]+\-([^\-\.\_]+).*\.combined.txt$/i)
			{
				my $what=$1;
				$what{$what}=1;
				if(open (IN, qq!$dir/$filename!))
				{
					print qq!$what\n!;
					while($line = <IN>)
					{
						chomp($line);
						if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
						{
							my $title=$1;
							my $expect=$2;
							my $pep=$3;
							my $prot=$4;
							$quant{"$pep#$what#A"}=$5;
							$quant{"$pep#$what#B"}=$6;
							$quant{"$pep#$what#C"}=$7;
							$quant{"$pep#$what#D"}=$8;
							$quant{"$pep#$what#E"}=$9;
							$quant{"$pep#$what#F"}=$10;
							while($prot=~s/^#([^#]+)#//)
							{
								my $prot_=$1;
								$prot_=~s/\|/_/g;
								if ($prot{$pep}!~/#$prot_#/)
								{
									$prot{$pep}.="#$prot_#";
									$protein_peptides{$prot_}.="#$pep#";
									$protein_peptides_count{$prot_}++;
								}
							}
						}
						else
						{
							if ($line=~/\w/) { print qq!Error: $line\n!;}
						}
					}
					close(IN);
				}
				my %normalization=();
				foreach my $what (sort keys %what) 
				{ 
					$normalization{$what}="";
					foreach my $letter ("A","B","C","D","E","F") 
					{ 
						if ($normalization{$what}!~/\w/)
						{
							if ($codes{"$what$letter"}=~/^HIV\-$/i)
							{
								$normalization{$what}="$what#$letter";
							}
						}
					}
					foreach my $pep (sort keys %prot)
					{
						if ($quant{"$pep#$normalization{$what}"}>0)
						{
							foreach my $letter ("A","B","C","D","E","F") 
							{ 
								$quant_norm{"$pep#$what#$letter"}=$quant{"$pep#$what#$letter"}/$quant{"$pep#$normalization{$what}"};
							}
						}
					}
				}
				if(open (OUT, qq!>$dir/all_pep.txt!))
				{
					print OUT qq!pep\tprot!;
					foreach my $what (sort keys %what) 
					{ 
						foreach my $letter ("A","B","C","D","E","F") 
						{ 
							print OUT qq!\t$codes{"$what$letter"} $what$letter!; 
						}
					}
					print OUT qq!\n!; 
					foreach my $pep (sort keys %prot)
					{
						print OUT qq!$pep\t$prot{$pep}!;
						foreach my $what (sort keys %what) 
						{ 
							foreach my $letter ("A","B","C","D","E","F") 
							{ 
								print OUT qq!\t$quant{"$pep#$what#$letter"}!; 
							}
						}
						print OUT qq!\n!; 
					}
					close(OUT);
				}				
				if(open (OUT, qq!>$dir/all_pep_norm.txt!))
				{
					print OUT qq!pep\tprot!;
					foreach my $what (sort keys %what) 
					{ 
						foreach my $letter ("A","B","C","D","E","F") 
						{ 
							print OUT qq!\t$codes{"$what$letter"} $what$letter!; 
						}
					}
					print OUT qq!\n!; 
					foreach my $pep (sort keys %prot)
					{
						print OUT qq!$pep\t$prot{$pep}!;
						foreach my $what (sort keys %what) 
						{ 
							foreach my $letter ("A","B","C","D","E","F") 
							{ 
								print OUT qq!\t$quant_norm{"$pep#$what#$letter"}!; 
							}
						}
						print OUT qq!\n!; 
					}
					close(OUT);
				}
				my @proteins_to_sort=();
				my $proteins_to_sort_count=0;
				foreach my $prot (keys %protein_peptides_count)
				{
					if ($protein_peptides_count{$prot}>0) 
					{
						$proteins_to_sort[$proteins_to_sort_count]=qq!$protein_peptides_count{$prot}#$prot!;
						$proteins_to_sort_count++;
					}
				}
				my @proteins_sorted = sort { $b <=> $a } @proteins_to_sort;
				my $proteins_sorted_count=0;
				my %protein_peptides_unique_count=();
				my $proteins_unique_count=0;
				my %peptides_done=();
				
				open (OUT, qq!>$dir/prot.txt!);
				open (OUT_ALL, qq!>$dir/all_prot.txt!);
				print OUT qq!prot\tdescription\tpeptides_count\tunique_peptides_count!;
				foreach my $what (sort keys %what) 
				{ 
					foreach my $letter ("A","B","C","D","E","F") 
					{ 
						print OUT qq!\t$codes{"$what$letter"} $what$letter!; 
					}
				}
				print OUT qq!\n!; 
				print OUT_ALL qq!prot\tdescription\tpeptides_count\tunique_peptides_count!;
				
				open (OUT_NORM, qq!>$dir/prot_norm.txt!);
				open (OUT_ALL_NORM, qq!>$dir/all_prot_norm.txt!);
				print OUT_NORM qq!prot\tdescription\tpeptides_count\tunique_peptides_count!;
				foreach my $what (sort keys %what) 
				{ 
					foreach my $letter ("A","B","C","D","E","F") 
					{ 
						print OUT_NORM qq!\t$codes{"$what$letter"} $what$letter!; 
					}
				}
				print OUT_NORM qq!\n!; 
				print OUT_ALL_NORM qq!prot\tdescription\tpeptides_count\tunique_peptides_count!;
				
				foreach my $what (sort keys %what) 
				{ 
					foreach my $letter ("A","B","C","D","E","F") 
					{ 
						print OUT_ALL_NORM qq!\t$codes{"$what$letter"} $what$letter!; 
					}
				}
				print OUT_ALL_NORM qq!\n!; 
				for($proteins_sorted_count=0;$proteins_sorted_count<$proteins_to_sort_count;$proteins_sorted_count++)
				{
					if ($proteins_sorted[$proteins_sorted_count]=~/#([^#]+)$/)
					{
						my $name=$1;
						$protein_peptides_unique_count{$name}=0;
						my $temp=$protein_peptides{$name};
						my %peptides_done_this=();
						while($temp=~s/^#([^#]+)#//)
						{
							my $pep=$1;
							if ($peptides_done_this{$pep}!~/\w/)
							{
								$peptides_done_this{$pep}=1;
							}
							if ($peptides_done{$pep}!~/\w/)
							{
								$peptides_done{$pep}=1;
								$protein_peptides_unique_count{$name}++;
							}
						}
						foreach my $what (sort keys %what) 
						{ 
							foreach my $letter ("A","B","C","D","E","F") 
							{ 
								my $temp=$protein_peptides{$name};
								my @temp=();
								my $temp_count=0;
								while($temp=~s/^#([^#]+)#//)
								{
									my $pep=$1;
									$temp[$temp_count++]=$quant{"$pep#$what#$letter"};
								}
								if ($temp_count>0)
								{
									if ($temp_count==1) { $quant_prot{"$name#$what#$letter"}=$temp[0]; }
									else 
									{ 
										my @temp_sorted = sort { $a <=>$b } @temp;
										my $l=int($temp_count/2);
										if ($temp_count%2==0) { $quant_prot{"$name#$what#$letter"}=($temp[$l-1]+$temp[$l])/2; }
										else { $quant_prot{"$name#$what#$letter"}=$temp[$l]; }
									}
								}
								if ($quant_prot{"$name#$normalization{$what}"}>0)
								{
									$quant_norm_prot{"$name#$what#$letter"}=$quant_prot{"$name#$what#$letter"}/$quant_prot{"$name#$normalization{$what}"};
								}
							}
						}
						print OUT_ALL qq!$name\t$descriptions{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}!;
						foreach my $what (sort keys %what) 
						{ 
							foreach my $letter ("A","B","C","D","E","F") 
							{ 
								print OUT_ALL qq!\t$quant_prot{"$name#$what#$letter"}!; 
							}
						}
						print OUT_ALL qq!\n!;
						if ($protein_peptides_unique_count{$name}>1)
						{
							print OUT qq!$name\t$descriptions{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}!;
							foreach my $what (sort keys %what) 
							{ 
								foreach my $letter ("A","B","C","D","E","F") 
								{ 
									print OUT qq!\t$quant_prot{"$name#$what#$letter"}!; 
								}
							}
							print OUT qq!\n!;
							$proteins_unique_count++;
						}
						
						print OUT_ALL_NORM qq!$name\t$descriptions{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}!;
						foreach my $what (sort keys %what) 
						{ 
							foreach my $letter ("A","B","C","D","E","F") 
							{ 
								print OUT_ALL_NORM qq!\t$quant_norm_prot{"$name#$what#$letter"}!; 
							}
						}
						print OUT_ALL_NORM qq!\n!;
						if ($protein_peptides_unique_count{$name}>1)
						{
							print OUT_NORM qq!$name\t$descriptions{$name}\t$protein_peptides_count{$name}\t$protein_peptides_unique_count{$name}!;
							foreach my $what (sort keys %what) 
							{ 
								foreach my $letter ("A","B","C","D","E","F") 
								{ 
									print OUT_NORM qq!\t$quant_norm_prot{"$name#$what#$letter"}!; 
								}
							}
							print OUT_NORM qq!\n!;
							$proteins_unique_count++;
						}
					}
				}
				close(OUT);
				close(OUT_ALL);
				close(OUT_NORM);
				close(OUT_ALL_NORM);
			}
		}
	}
}


