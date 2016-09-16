use strict;

my $error=0;
my $filename="";
my $multimers=1;
my $multimers_only=1;
my $myPEP="";
my $line="";
my $PEP_cont=0;
my @PEP=();
my @Y_cont=();

if ($ARGV[0]=~/\w/) { $filename=$ARGV[0];} else { $filename="peptides.txt"; }
if ($ARGV[1]=~/\w/) { $multimers=$ARGV[1];} else { $multimers=1; }
if ($ARGV[2]=~/\w/) { $multimers_only=$ARGV[2];} else { $multimers_only=0; }

if (open (OUT,">$filename-crosslinks.txt"))
{
	print OUT qq!#Tyrosine\t#CrossLink\t#Seg\tSeg1\tSeg3\tSeg3\n!;
	if (open (IN,"$filename"))
	{
		while ($line=<IN>)
		{
			chomp($line); 
			$PEP[$PEP_cont]=$line;
			$Y_cont[$PEP_cont]=($line=~tr/Y/Y/);
			if (length($PEP[$PEP_cont])>5)
			{
				my $cross_cont=$Y_cont[$PEP_cont];
				my $half=$cross_cont/2;
				for (my $k=1-1; $k<=$half; $k++)
				{
					if ($multimers_only==0) { print OUT qq!$cross_cont\t$k\t1\t$PEP[$PEP_cont]\t\t\n! }
				}
			}
			if($line=~/Y/)
			{
				print "$PEP_cont, $PEP[$PEP_cont], $Y_cont[$PEP_cont]\n";
				$PEP_cont++;
			} 
		}
	}
	close(IN);

	for(my $i=0; $i<$PEP_cont; $i++)
	{
		for(my $j=$i+1-$multimers; $j<$PEP_cont and ($multimers_only==0 or $j==$i); $j++)
		{
			my $cross_cont=$Y_cont[$i]+$Y_cont[$j];
			my $half=$cross_cont/2;
			for (my $k=2-1; $k<=$half; $k++)
			{
				print OUT qq!$cross_cont\t$k\t2\t$PEP[$i]\t$PEP[$j]\t\n!
			}
		}
	}
	for(my $i=0; $i<$PEP_cont; $i++)
	{
		for(my $j=$i+1-$multimers; $j<$PEP_cont and ($multimers_only==0 or $j==$i); $j++)
		{
			for(my $n=$j+1-$multimers; $n<$PEP_cont and ($multimers_only==0 or $n==$j); $n++)
			{
				my $cross_cont=$Y_cont[$i]+$Y_cont[$j]+$Y_cont[$n];
				my $half=$cross_cont/2;
				for (my $k=3-1; $k<=$half; $k++)
				{
					print OUT qq!$cross_cont\t$k\t3\t$PEP[$i]\t$PEP[$j]\t$PEP[$n]\n!
				}
			}
		}
	}
	close(OUT);
}
