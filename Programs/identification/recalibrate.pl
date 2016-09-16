#!c:/perl/bin/perl.exe
#

my $error=0;
my $mgffilename="";
my $xmlfilename="";
my $dir="";
my $ms1_cal_type="";
my $ms2_cal_type="";
if ($ARGV[0]=~/\w/) { $xmlfilename=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $method=$ARGV[1];} else { $error=1; }

if($method=~/^([a-zA-Z0-9]+)\s+([a-zA-Z0-9]+)$/)
{
	$ms1_cal_type="rt"; 
	$ms2_cal_type="mz";
}
if($method=~/^([a-zA-Z0-9]+)$/)
{
	$ms1_cal_type="rt";
}
$dir=$xmlfilename;
$dir=~s/\/([^\/]+)\.xml$//;

$xmlfilename=~s/\\/\//g;
my $xmlfilename_=$xmlfilename;
if ($xmlfilename_!~s/\.xml$//i) { $error=1; }
my $xmlfilename__=$xmlfilename_;
$xmlfilename__=~s/\/([^\/]+)$/$1/;
my @ms1_cal=();
my $ms1_cal_max=0;
my @ms2_cal=();
my $ms2_cal_max=0;
if ($error==0)
{
	open (IN,"$xmlfilename") || die "Could not open $xmlfilename\n";
	while ($line=<IN>)
	{										
		if ($line=~/\<note type=\"input\" label=\"spectrum\, path\"\>.*\/(.*)\.mgf\<\/note>/i)
		{
			$mgffilename=$1;  
		}
	}
	close(IN);
	if (open (IN,"$dir/$xmlfilename__-lim-$ms1_cal_type.txt"))
	{
		print qq!$xmlfilename__-lim-$ms1_cal_type.txt\n!;
		$line=<IN>;
		$x_prev=-1;
		while($line=<IN>)
		{
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/)
			{
				my $x=int($1);
				my $y=$6;
				for(my $i=$x_prev+1;$i<=$x;$i++)
				{
					$ms1_cal[$i]=$y;
					if ($ms1_cal_max<$i) { $ms1_cal_max=$i; }
				}
				$x_prev=$x;
			}
		}
		close(IN);
	}
	if (open (IN,"$dir/$xmlfilename__-lim-$ms2_cal_type-MS2.txt"))
	{
		print qq!$xmlfilename__-lim-$ms2_cal_type-MS2.txt\n!;
		$line=<IN>;
		$x_prev=-1;
		while($line=<IN>)
		{
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)/)
			{
				my $x=int($1);
				my $y=$6;
				for(my $i=$x_prev+1;$i<=$x;$i++)
				{
					$ms2_cal[$i]=$y;
					if ($ms2_cal_max<$i) { $ms2_cal_max=$i; }
				}
				$x_prev=$x;
			}
		}
		close(IN);
	}
	if (open (IN,qq!$dir/$mgffilename.mgf!) or open (IN,qq!$dir/$mgffilename.MGF!))
	{		
		$cal_mgffile=$xmlfilename_."\_cal\.mgf"; 
		if (open (OUT,">$cal_mgffile"))
		{	
			my $header="";
			my $pepmass="";
			my $title="";
			my $charge="";
			my $rt="";
			my $started_reading_header=0;
			my $started_reading_fragments=0;
			my $done_reading_fragments=0;
			while($line=<IN>)
			{
				if ($line=~/^BEGIN IONS/) { $started_reading_header=1; }
				if ($line=~/^([0-9\.\+\-edED]+)\s([0-9\.\+\-edED]+)/)
				{
					my $mz=$1;
					if ($started_reading_fragments==0)
					{
						my $pepmass_cal=$pepmass;
						my $digits=4;
						if ($pepmass_cal=~/\.(.*)$/) { $digits=length($1); }
						if ($ms1_cal_type=~/^rt$/)
						{
							my $i=int($rt);
							if ($i>$ms1_cal_max) { $i=$ms1_cal_max; }
							if ($i<0) { $i=0; }
							$pepmass_cal*=(1-$ms1_cal[$i]/1e+6);
							$pepmass_cal*=10**$digits;
							$pepmass_cal=int($pepmass_cal+0.5);
							$pepmass_cal/=10**$digits;
						}
						$header=~s/PEPMASS=([0-9\.\-\+edED]+)/PEPMASS=$pepmass_cal/m;
						print OUT $header;
					}
					$started_reading_fragments=1;
					my $mz_cal=$mz;
					my $digits=4;
					if ($mz_cal=~/\.(.*)$/) { $digits=length($1); }
					if ($ms2_cal_type=~/^mz$/)
					{
						my $i=int($mz);
						if ($i>$ms2_cal_max) { $i=$ms2_cal_max; }
						if ($i<0) { $i=0; }
						$mz_cal*=(1-$ms2_cal[$i]/1e+6);
						$mz_cal*=10**$digits;
						$mz_cal=int($mz_cal+0.5);
						$mz_cal/=10**$digits;
					}
					$line=~s/^([0-9\.\-\+edED]+)/$mz_cal/;
					print OUT $line;
				}
				else
				{
					if ($started_reading_fragments==1)
					{
						$done_reading_fragments=1;
					}
				}
				if ($started_reading_header==1 and $started_reading_fragments==0)
				{
					if ($line=~/^PEPMASS=([0-9\.\-\+edED]+)\s?([0-9\.\-\+edED]*)\s*$/)
					{
						$pepmass=$1;
					}
					if ($line=~/^TITLE=(.*)$/)
					{
						$title=$1;
						#print qq!$title\n!;
					}
					if ($line=~/^CHARGE=([0-9\.\-\+edED]+)\s*$/)
					{
						$charge=$1;
					}
					if ($line=~/^RTINSECONDS=([0-9\.\-\+edED]+)\s*$/)
					{
						$rt=$1;
					}
					$header.=$line;
				}
				if ($done_reading_fragments==1)
				{
					print OUT $line;
					$header="";
					$pepmass="";
					$title="";
					$charge="";
					$rt="";
					$started_reading_header=0;
					$started_reading_fragments=0;
					$done_reading_fragments=0;
				}
			}			
			close(OUT);
		}
		close(IN);
	}
}
