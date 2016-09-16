#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $dir="";
my $expect_threshold="";
if ($ARGV[0]=~/\w/) { $dir=$ARGV[0];} else { $dir="."; }
if ($ARGV[1]=~/\w/) { $expect_threshold=$ARGV[1];} else { $expect_threshold=1e-2; }

if ($error==0)
{
	$dir=~s/\\/\//g;
	open (LOG,qq!>$dir.$expect_threshold.log!) || die "Could not open output\n";
	my $line="";
	if (opendir(dir,"$dir"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $filename (@allfiles)
		{
			if ($filename=~/\.xml$/i)
			{
				open (IN,"$dir/$filename") || die "Could not open $dir/$filename\n";
				open (OUT,qq!>$dir/$filename.peptide_list.$expect_threshold.out!) || die "Could not open output\n";
				my $reversed=1;
				my $pep="";
				my $expect="";
				my $peptide_proteins="";
				while ($line=<IN>)
				{
					if ($line=~/^\<protein\s+.*label="([^\"]+)"/)
					{
						my $protein_name=$1;
						my $protein=$protein_name;
						$protein=~s/^(\S+)\s.*$/$1/;
						if ($protein_name!~/\:reversed$/) { $reversed=0; }
						$peptide_proteins.="#$protein#";
					}
					if ($line=~/^\<domain\s+id="([0-9\.edED\+\-]+)".*expect="([0-9\.edED\+\-]+)".*mh="([0-9\.edED\+\-]+)".*delta="([0-9\.edED\+\-]+)".*seq="([A-Z]+)"/)
					{
						my $expect_=$2;
						my $pep_=$5;
						$pep_=~tr/L/I/;
						$pep=~tr/L/I/;
						if ($expect!~/\w/ or $expect_<=$expect) { $expect=$expect_; $pep=$pep_; }
					}
					if($line=~/<note label=\"Description\">(.+?)<\/note>/)	
					{
						my $title=$1;
						if ($reversed==0 and $expect<$expect_threshold)
						{
							print OUT qq!$title\t$expect\t$pep\t$peptide_proteins\n!;
						}
						$reversed=1;
						$pep="";
						$expect="";
						$peptide_proteins="";
					}
				}	
				close(IN);
				close(OUT);	
			}
		}
	}
	close(LOG);
}