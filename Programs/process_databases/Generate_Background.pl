#!/usr/local/bin/perl

sub numerically { $a <=> $b; }
$proton_mass=1.007276;

$error=0;
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $number_of_fragments=$ARGV[1];} else { $number_of_fragments=5; }
if ($ARGV[2]=~/\w/) { $number_of_files=$ARGV[2];} else { $number_of_files=10; }
if ($ARGV[3]=~/\w/) { $srand=$ARGV[3];} else { $srand=13579; }

srand($srand);
mkdir("$dir/$number_of_fragments-$number_of_files-$srand");
$pep_count=0;
$frag_count=0;
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
				if ($filename=~/^(.*)\.([0-9]+)\.([0-9]+\.?[0-9]*)\.([0-9]+)\.([0-9]+)\.([A-Z]+)\.([0-9]+)\.([abcxyz]+)\.([0-9]+)\.([0-9]+)\.mgf/i)
				{
					$filename_1="$1.$2.$3";
					$filename_2="$7.$8.$9";
					if(open (IN, "$dir/background/$filename"))
					{
						while($line=<IN>)
						{
							if ($line=~/^PEPMASS=([0-9\.\+\-edED]+)/)
							{
								$mz=$1;
								$peptide_masses[$pep_count++]=$mz;
							}
							if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
							{
								$mz=$1;
								$fragment_masses[$frag_count++]=$mz;
							}
						}
						close(IN);
					}
				}
			}
		}
	}
	for($i=0;$i<$number_of_files;$i++)
	{
		$filename_="$filename_1.$number_of_fragments.$number_of_fragments.XXXXXX.$filename_2.$i.mgf";
		if(open (OUT, ">$dir/$number_of_fragments-$number_of_files-$srand/$filename_"))
		{
			@saved_peaks=();
			%frags_used=();
			$pep_ind=rand()*$pep_count;
			$pep_ind=~s/\..*$//;
			print OUT qq!BEGIN IONS
TITLE=Background, mz=$peptide_masses[$pep_ind], z=2, $number_of_fragments
PEPMASS=$peptide_masses[$pep_ind]
CHARGE=2+
!;
			for($bgr=0;$bgr<$number_of_fragments;$bgr++)
			{
				$frag_ind=rand()*$frag_count;
				$frag_ind=~s/\..*$//;
				$mz=$fragment_masses[$frag_ind];
				$mz_=$mz+0.5;
				$mz_=~s/\..*$//;
				while ($frags_used{$mz_}=~/\w/)
				{
					$frag_ind=rand()*$frag_count;
					$frag_ind=~s/\..*$//;
					$mz=$fragment_masses[$frag_ind];
					$mz_=$mz+0.5;
					$mz_=~s/\..*$//;
				}
				$frags_used{$mz_}=1;
				$frags_used{$mz_-1}=1;
				$frags_used{$mz_+1}=1;
				$saved_peaks[$bgr]="$mz 100\n";
			}
			@sorted_saved_peaks= sort numerically @saved_peaks;
			for($bgr=0;$bgr<$number_of_fragments;$bgr++)
			{
				print OUT "$sorted_saved_peaks[$bgr]";
			}
			print OUT "END IONS\n\n";
			close(OUT);
		}		
	}
}

