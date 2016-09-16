#!/usr/local/bin/perl

sub numerically { $a <=> $b; }

$error=0;
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $percent=$ARGV[1];} else { $percent=0.8; }

$pep_count=0;
if ($error==0)
{
	if (opendir(dir,"$dir/background"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach $filename (@allfiles)
		{
			if ($filename=~/\w/i)
			{
				if ($filename=~/([0-9]+)\.([0-9]+\.?[0-9]*)\.([0-9]+)\.([0-9]+)\.([A-Z]+)\.([0-9]+)\.([abcxyz]+)\.([0-9]+)\.([0-9]+)\.mgf/i)
				{
					$pep=$5;
					if ($peptides!~/#$pep#/)
					{
						$peptide[$pep_count]=$pep;
						$peptide_index{$pep}=$pep_count;
						$fragment_count[$pep_count]=0;
					}
					if(open (IN, "$dir/background/$filename"))
					{
						while($line=<IN>)
						{
							if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
							{
								$mz=$1;
								$mz_=$mz+0.5;
								$mz_=~s/\..*$//;
								$fragment_masses{"$pep#$mz_"}=$mz;
							}
						}
						close(IN);
					}
					if ($peptides!~/#$pep#/)
					{
						$peptides.="#$pep#";
						$pep_count++;
					}
				}
			}
		}
		
		foreach $key (%fragment_masses)
		{
			if ($key=~/^([^#]+)#/)
			{
				$pep=$1;
				
				$fragment_masses[$peptide_index{$pep}][$fragment_count[$peptide_index{$pep}]]=$fragment_masses{$key};
				$fragment_count[$peptide_index{$pep}]++;
			}
		}
	}
	if (opendir(dir,"$dir/original"))
	{
		@allfiles=readdir dir;
		closedir dir;
		foreach $filename (@allfiles)
		{
			if ($filename=~/\w/i)
			{
				if ($filename=~/^(.*)\.([0-9]+)\.([0-9]+\.?[0-9]*)\.([0-9]+)\.([0-9]+)\.([A-Z]+)\.([0-9]+)\.([abcxyz]+)\.([0-9]+)\.([0-9]+)\.mgf/i)
				{
					$filename_1="$1.$2.$3.$4";
					$filename_2="$6.$7.$8.$9.$10";
					$peaks=$4;
					$peaks_tot=$5;
					$pep=$6;
					$peaks_bgr=$peaks/(1.0/$percent-1)+0.5;
					$peaks_bgr=~s/\..*$//;
					$peaks_tot=$peaks+$peaks_bgr;
					$filename_="$filename_1.$peaks_tot.$filename_2.mgf";
					#print "$pep peaks=$peaks, peaks_bgr=$peaks_bgr, peaks_tot=$peaks_tot\n   $filename\n   $filename_\n";
					if ($peaks_bgr<=2*($pep_count-1))
					{
						if(open (IN, "$dir/original/$filename"))
						{
							if(open (OUT, ">$dir/$filename_"))
							{
								$peaks_count_=0;
								@saved_peaks=();
								%frags_used=();
								while($line=<IN>)
								{
									if ($line=~/^END IONS$/)
									{
										%peptides_used=();
										$peptides_used{$pep}=10000;
										for($bgr=0;$bgr<$peaks_bgr;$bgr++)
										{
											$pep_ind=rand()*$pep_count;
											$pep_ind=~s/\..*$//;
#print "*$bgr $pep_ind $pep_count $peptide[$pep_ind] $peptides_used{$peptide[$pep_ind]}\n";
											while ($peptides_used{$peptide[$pep_ind]}>=2)
											{
												$pep_ind=rand()*$pep_count;
												$pep_ind=~s/\..*$//;
											}
											$peptides_used{$peptide[$pep_ind]}++;
#print "#$bgr $pep_ind $pep_count $peptide[$pep_ind] $peptides_used{$peptide[$pep_ind]}\n";

											$frag_ind=rand()*$fragment_count[$pep_ind];
											$frag_ind=~s/\..*$//;
											$mz=$fragment_masses[$pep_ind][$frag_ind];
											$mz_=$mz+0.5;
											$mz_=~s/\..*$//;
#print "   *$pep_ind,$frag_ind $mz $mz_ #$frags_used{$mz_}# $fragment_count[$pep_ind]\n";
											while ($frags_used{$mz_}=~/\w/)
											{
												$frag_ind=rand()*$fragment_count[$pep_ind];
												$frag_ind=~s/\..*$//;
												$mz=$fragment_masses[$pep_ind][$frag_ind];
												$mz_=$mz+0.5;
												$mz_=~s/\..*$//;
											}
											$frags_used{$mz_}=1;
											$frags_used{$mz_-1}=1;
											$frags_used{$mz_+1}=1;
											$saved_peaks[$peaks_count_++]="$mz 100\n";
											#$saved_peaks[$peaks_count_++]="$mz 100 $peptide[$pep_ind]\n";
#print "   #$pep_ind,$frag_ind $mz $mz_ #$frags_used{$mz_}# $fragment_count[$pep_ind]\n";
										}
										for $line_ (sort numerically @saved_peaks)
										{
											print OUT $line_;
										}
									}
									if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
									{
										$mz=$1;
										$mz_=$mz+0.5;
										$mz_=~s/\..*$//;
										$frags_used{$mz_}=1;
										$frags_used{$mz_-1}=1;
										$frags_used{$mz_+1}=1;
										$saved_peaks[$peaks_count_++]="$mz 100\n";
									}
									else
									{
										print OUT $line;
									}
								}
								close(OUT);
							}
							close(IN);
						}
					}
					else { print "Error: Fewer peptides than background peaks needed: $peaks_bgr>2*($pep_count-1) ($filename)\n";}
				}
			}
		}
	}
}

