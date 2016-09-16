#!/usr/local/bin/perl
#

require "./masses_and_fragments.pl";

$error=0;
if ($ARGV[0]=~/\w/) { $DBfilename=$ARGV[0];} else { $DBfilename="test.fasta"; }
if ($ARGV[3]=~/\w/) { $number_of_fragments=$ARGV[3];} else { $number_of_fragments="15"; }
if ($ARGV[5]=~/\w/) { $phospho=$ARGV[5];} else { $phospho=0; }
if ($ARGV[6]=~/\w/) { $charge=$ARGV[6];} else { $charge=2; }
if ($ARGV[7]=~/\w/) { $ion_types=$ARGV[7];} else { $ion_types="by"; }
if ($ARGV[8]=~/\w/) { $srand=$ARGV[8];} else { $srand=13579; }

$total_pep_count=0;
$total_pep_count_max=50;
$iterations=1;
system(qq!del "$DBfilename.*.mgf"!);
$number_of_fragments_=$number_of_fragments;
@number_of_fragments=();
$max_number_of_fragments=0;
while($number_of_fragments_=~s/^\s*([0-9]+)\s*,?\s*//) 
{ 
	@number_of_fragments=(@number_of_fragments,$1); 
	if ($max_number_of_fragments<$1) { $max_number_of_fragments=$1; }
}
srand($srand);
my %PEP=();
$files_count=0;
$peptides_count=0;
$proteins_count=0;
if (open (IN,"$DBfilename"))
{
	$name="";
	$sequence="";
	while ($line=<IN> and $total_pep_count<$total_pep_count_max)
	{
		chomp($line);
		if ($line=~/^>(\S+)\s?(.*)$/)
		{
			$name_=$1;
			if ($name=~/\w/ and $sequence=~/\w/)
			{
				$proteins_count++;
				print "$proteins_count. $name\n";
				%PEP=();
				DigestTrypsin($name,$sequence,$incompletes);
				write_mgf($iterations);
			}
			$name=$name_;
			$description=$description_;
			$sequence="";
		}
		else
		{
			$sequence.="$line";
		}
	}	
	if ($name=~/\w/ and $sequence=~/\w/ and $total_pep_count<$total_pep_count_max)
	{

		$proteins_count++;
		print "$proteins_count. $name\n";
		%PEP=();
		DigestTrypsin($name,$sequence,$incompletes);
		write_mgf($iterations);
	}
	close(IN);
}

sub DigestTrypsin
{
	my $name = shift();
	my $seq = shift();
	my $incompletes = shift();

	my $temp=$seq;
	my @pep=();
	my @start=();
	my @end=();
	my $aa="";
	my $aa_="";
	my $i=0;

	for($i=0;$i<=$incompletes;$i++)
	{
		$start[$i]=0;
		$end[$i]=-1;
		#$pep[$i]="[";
	}
	my $aa_count=0;
	while ($temp=~s/^\s*([A-Z])//)
	{
		$aa=$1;
		if ( ($aa_=~/R/ or $aa_=~/K/) and $aa!~/P/)
		{
			for($i=0;$i<=$incompletes;$i++)
			{
				$pep[$i]=~s/I/L/g;
				$PEP{"$pep[$i]"}=1;
				$pep[$i]=$pep[$i+1];
				$start[$i]=$start[$i+1];
				$end[$i]=$end[$i+1];
			}
			$start[$incompletes]=$aa_count;
			$end[$incompletes]=$aa_count-1;
		}
		for($i=0;$i<=$incompletes;$i++)
		{
			$pep[$i].=$aa;
			$end[$i]++;
		}
		$aa_=$aa;
		$aa_count++;
	}
	for($i=0;$i<=$incompletes;$i++)
	{
		$pep[$i]=~s/I/L/g;
		$PEP{"$pep[$i]"}=1;
	}
}


sub write_mgf
{
	my $iterations = shift();
	my $done_this_proteins=0;
	my $i=0;
	my $j=0;

	foreach $peptide (keys %PEP)
	{
		if (length($peptide)>6)
		{
			$ok=1;
			@phospho_sites=();
			$phospho_sites_count=0;
			$phospho_index=",";
			$phospho_index_all=",";
			if ($phospho>0)
			{
				$index=0;
				$peptide_=$peptide;
				while ($peptide_=~s/^([A-Z])//)
				{
					$aa=$1;
					if ($aa=~/S/ or $aa=~/T/ or $aa=~/Y/) 
					{ 
						$phospho_sites[$phospho_sites_count++]=$index;
						$phospho_index_all.="$index,";
					}
					$index++;
				}
				if ($phospho_sites_count<$phospho) { $ok=0; }
				else
				{
					if ($phospho_sites_count==$phospho)
					{
						for ($j=0;$j<$phospho_sites_count;$j++) { $phospho_index.="$phospho_sites[$j],";}
					}
					else
					{
						$phospho_sites_count_=0;
						while ($phospho_sites_count_<$phospho)
						{
							$j=rand()*$phospho_sites_count;
							$j=~s/\..*$//;
							if ($phospho_index!~/,$phospho_sites[$j],/)
							{
								$phospho_index.="$phospho_sites[$j],";
								$phospho_sites_count_++;
							}
						}
					}
				}
			}
			$phospho_index_=$phospho_index;
			$phospho_index_=~s/^\,//;
			$phospho_index_=~s/\,$//;
			$phospho_index_all_=$phospho_index_all;
			$phospho_index_all_=~s/^\,//;
			$phospho_index_all_=~s/\,$//;
			$MH=PepMH($peptide,$phospho_index_);
			if ($ok==1)
			{
				#print "*$peptide $MH,$parent_mass,$parent_mass_error,#$phospho_index_#$phospho_index_all_#\n";
				@fragments=();
				Fragments($peptide,$phospho_index_,$ion_types);
				$fragments=@fragments;
				$mz=Pepmz($peptide,$charge,$phospho_index_);
				$mz_=int($mz+0.5);
				foreach $number_of_fragments_ (@number_of_fragments)
				{
					#print "$peptides_count. #$number_of_fragments_#\n";
					if ($number_of_fragments_=~/([0-9]+)/)
					{
						if (2*(length($peptide)-1)>$number_of_fragments_)
						{
							print "$peptide $MH $number_of_fragments_\n";	
							for($iter=0;$iter<$iterations;$iter++)
							{
								@selected=();
								#print "$peptide $number_of_fragments_ ($fragments)\n";
								$found=0;
								while($found<$number_of_fragments_)
								{
									$i=rand()*$fragments;
									$i=~s/\..*$//;
									if ($selected[$i]!~/\w/)
									{
										$selected[$i]=1;
										$found++;
									}
								}
								@fragments_=();
								$found=0;
								for($i=0;$i<$fragments;$i++)
								{
									if($selected[$i]=~/\w/)
									{
										$fragments_[$found++]=$fragments[$i]; 
									}
								}
								if (open(outfile,"$DBfilename.$mz_.$number_of_fragments_.$peptide.$charge.$ion_types.$srand.$iter.mgf"))
								{
									close(outfile);
								}
								else
								{
									if (open(outfile,">$DBfilename.$mz_.$number_of_fragments_.$peptide.$charge.$ion_types.$srand.$iter.mgf"))
									{
										print outfile qq!BEGIN IONS\n!;
										print outfile qq!TITLE=$peptide, MH=$MH, z=$charge, mz=$mz $ion_types, phospho=$phospho_index_ ($phospho_index_all_), $number_of_fragments_ ($fragments)\n!;
										print outfile qq!PEPMASS=$mz\n!;
										print outfile qq!CHARGE=$charge+\n!;
										foreach $fragment (sort numerically @fragments_)
										{
											print outfile "$fragment 100\n";
										}
										print outfile qq!END IONS\n\n!;
										$files_count++;
										close(outfile);
										if ($max_number_of_fragments==$number_of_fragments_ and $iter==0) { $total_pep_count++; }
									}
									else
									{
										print "Error opening $DBfilename.$mz_.$number_of_fragments_.$peptide.$charge.$ion_types.$srand.$iter.mgf\n";
									}
								}
							}
						}
					}
					else
					{
						print "Error\n";
					}
				}
			}
		}
	}
}
