#!c:/perl/bin/perl.exe
#
#

$error=0;
if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="uniprot_sprot_human.dat"; } 

$filename_res=$filename;
$filename_res=~s/\.dat$//i;
$filename_res.=".fasta";

if ($error==0)
{
	open (IN,"$filename") || die "Could not open $filename\n";
	open (OUT,">$filename_res") || die "Could not open $filename_res\n";
	$id="";
	$de="";
	$gn="";
	$sq="";
	$sq_started=0;
	$de_ended=0;
	while ($line=<IN>)
	{
		chomp($line);
		if ($line=~/^\/\//)
		{
			if ($id=~/\w/ and $sq=~/\w/)
			{
				print OUT qq!>$id $gn$de\n$sq\n!;
			}
			else
			{
				print qq!Error $id $sq\n!;
			}
			$id="";
			$de="";
			$gn="";
			$sq="";
			$sq_started=0;
			$de_ended=0;
		}
		else
		{
			if ($line=~/^ID\s+(\S+)/)
			{
				$id=$1;
			}
			if ($line=~/^DE\s+(.*)$/)
			{
				$de_=$1;
				if ($de_=~/Contains:/ or $de_=~/Includes:/ or $de_=~/Flags:/) { $de_ended=1; }
				if ($de_ended==0)
				{
					$de_=~s/^RecName:\s*//;
					$de_=~s/^AltName:\s*//;
					$de_=~s/^SubName:\s*//;
					$de_=~s/^Full=*//;
					$de_=~s/^Short=*//;
					$de.=$de_;
				}
			}
			if ($line=~/^GN\s+Name=(\S+)$/)
			{
				$gn=$1;
			}
			if ($sq_started==1)
			{
				$line=~s/\s//gm;
				$sq.=$line;
			}
			if ($line=~/^SQ/)
			{
				$sq_started=1;
			}
		}
	}
	close(IN);
	close(OUT);	
}

