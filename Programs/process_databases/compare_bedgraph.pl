#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $filename_bedgraph1="";
my $filename_bedgraph2="";

if ($ARGV[0]=~/\w/) { $filename_bedgraph1=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $filename_bedgraph2=$ARGV[1];} else { $error=1; }

$filename_bedgraph1=~s/\.bedgraph$//i;
$filename_bedgraph2=~s/\.bedgraph$//i;

if ($error==0)
{
	open (LOG,">$filename_bedgraph1-$filename_bedgraph2.bedgraph.log");
	open (OUT_GRAPH,">$filename_bedgraph1-$filename_bedgraph2.bedgraph");
	print OUT_GRAPH qq!track type=bedGraph name="$filename_bedgraph1 $filename_bedgraph2 Graph" description="$filename_bedgraph1 $filename_bedgraph2 Graph" visibility=full color=200,100,0 altColor=0,100,200 priority=20\n!;
	my $line="";
	my %bedgraph=();
	my %bedgraph1=();
	my %bedgraph2=();
	if (open (IN,"$filename_bedgraph1.bedgraph"))
	{
		$line=<IN>;
		chomp($line);
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $chr=$1;
				my $start=$2;
				my $end=$3;
				my $value=$4;
				my $chr_=$chr;
				$chr_=~s/^chr//;
				if ($chr_<10) { $chr_="0$chr_";}
				$bedgraph{"$chr_:$start-$end"}=$line;
				$bedgraph1{"$chr_:$start-$end"}=$line;
			} else { print LOG qq!Error parsing: $line!; }
		}
		close(IN);
	}
	if (open (IN,"$filename_bedgraph2.bedgraph"))
	{
		$line=<IN>;
		chomp($line);
		while ($line=<IN>)
		{
			chomp($line);
			if ($line=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
			{
				my $chr=$1;
				my $start=$2;
				my $end=$3;
				my $value=$4;
				my $chr_=$chr;
				$chr_=~s/^chr//;
				if ($chr_<10) { $chr_="0$chr_";}
				$bedgraph{"$chr_:$start-$end"}=$line;
				$bedgraph2{"$chr_:$start-$end"}=$line;
			} else { print LOG qq!Error parsing: $line!; }
		}
		close(IN);
	}
	foreach my $key (sort keys %bedgraph)
	{
		my $chr1="";
		my $start1="";
		my $end1="";
		my $value1="";
		my $chr2="";
		my $start2="";
		my $end2="";
		my $value2="";
		if ($bedgraph1{"$key"}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
		{
			$chr1=$1;
			$start1=$2;
			$end1=$3;
			$value1=$4;
		}
		if ($bedgraph2{"$key"}=~/^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)/)
		{
			$chr2=$1;
			$start2=$2;
			$end2=$3;
			$value2=$4;
		}
		#print qq!$key:$value1,$value2\n!;
		if ($value1>0 and $value2>0)
		{
			my $ratio=log($value1/$value2)/log(2);
			print OUT_GRAPH qq!$chr1\t$start1\t$end1\t$ratio\n!;
		}
		else
		{
			if ($value1>0) { print OUT_GRAPH qq!$chr1\t$start1\t$end1\t-10\n!; }
			else
			{
				if ($value2>0) { print OUT_GRAPH qq!$chr2\t$start2\t$end2\t10\n!; }
			}
		}
	}
	close(OUT_GRAPH);
	close(LOG);
}