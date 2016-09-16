#!c:/perl/bin/perl.exe
#

$error=0;

if ($ARGV[0]=~/\w/) { $db_dir=$ARGV[0];} else { $db_dir="."; }
if ($ARGV[1]=~/\w/) { $string=$ARGV[1];} else { $string="TGTTTAAACA"; }

$string = qq!\U$string!;

if ($error==0)
{
	opendir(dir,"$db_dir");
	@dbs = readdir dir;
	foreach $db (@dbs)
	{
		if ($db=~/\.fasta/i)
		{
			if (open (IN,"$db_dir/$db"))
			{
				$count{$db}=0;
				$count_comp{$db}=0;
				$count_all{$db}=0;
				$name="";
				$description="";
				$sequence="";
				$count_seq=0;
				while ($line=<IN>)
				{
					chomp($line);
					if ($line=~/^>(\S+)\s*(.*)$/)
					{
						$name_=$1;
						$description_=$2;
						$description=~s/[\t\n\r]/,/g;
						#if ($count_seq%1000==0) { print "$count_seq\n"; }
						$count_seq++;
						if ($name=~/\w/ and $sequence=~/\w/)
						{
							$count_all{$db}++;
							$match=0;
							$sequence = qq!\U$sequence!;
							if ($sequence=~/$string/) 
							{ 
								$match=1; 
								$index=0;
								$indexes="";
								$count_indexes=0;
								while(($index=index($sequence,$string,$index))>=0)
								{
									$pre = substr $sequence,$index-5,5;
									$post = substr $sequence,$index+length($string),5;
									#print qq!$pre-$post\n!;
									if ($pre=~/^$post$/) 
									{ 
										$count_indexes++;
										$indexes.="$index,";
									}
									$index++;
								}
							}
							$count{"$db#$count_indexes"}++;
							if ($count_indexes>=1)
							{
								$name__="";
								$expect="";
								$segments_query="";
								$segments_sbjct="";
								$start_query="";
								$start_sbjct="";
								$end_query="";
								$end_sbjct="";
								$start="";
								$end="";
								$start_="";
								$end_="";
								$end_prev="";
								$end_rev_="";
								$temp=$sequence;
								$temp=~s/$string.....//g;
								if (open (OUT_,">temp.fasta"))
								{
									print OUT_ qq!>$name\n$temp\n!;
									close(OUT_);
									system(qq!"D:\\Server\\blast\\ncbi-blast-2.2.25+\\bin\\blastn" -query temp.fasta -db db/HIV1_ENV.fasta -out blast/$name.txt!);
									if (open (IN_,"blast/$name.txt"))
									{
										while($line=<IN_>)
										{
											if ($line=~/^Query=\s*(\S+)/)
											{
												$name__=$1;
											}
											if ($line=~/^\s*Score\s*=\s*([0-9\.]+)\s*bits\s*.([0-9]+).,\s*Expect\s*=\s*([0-9edED\-\+\.]+)/)
											{
												$expect=$3;
											}
											if ($line=~/^Query\s*([0-9]+)\s+(\S+)\s+([0-9]+)/)
											{
												$start=$1;
												$seq=$2;
												$end=$3;
												if ($start_query!~/\w/) { $start_query=$start; }
												if ($end_query<$end) { $end_query=$end; }
												$line=<IN_>;
												if ($line=~/^\s+(\S+)/)
												{
													$alignment=$2;
												}
												$line=<IN_>;
												if ($line=~/^Sbjct\s*([0-9]+)\s+(\S+)\s+([0-9]+)/)
												{
													$start_=$1;
													$seq_=$2;
													$end_=$3;
													if ($start_sbjct>$start) { $start_sbjct=$start_; }
													if ($end_sbjct<$end_) { $end_sbjct=$end_; }
												}
												if ($seq=~/\w/ and $seq_=~/\w/)
												{
													if ($expect=~/\w/) 
													{
														$segments_query.="$expect:"; 
														$segments_sbjct.="$expect:"; 
														$expect="";
													} 
													$segments_query.="$start-$end,";
													$segments_sbjct.="$start_-$end_,";
													$start="";
													$end="";
													$start_="";
													$end_="";
												}
											}
										}
										close(IN_);
										system(qq!del temp.fasta!);
									}
								}
								$indexes=~s/\,\s*$//;
								print qq!$name\t$name__\t$count_indexes\t$indexes\t$segments_query\t$segments_sbjct\n!;
							}
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
				close(IN);
						
						
					
						if ($name=~/\w/ and $sequence=~/\w/)
						{
							$count_all{$db}++;
							$match=0;
							$sequence = qq!\U$sequence!;
							if ($sequence=~/$string/) 
							{ 
								$match=1; 
								$index=0;
								$indexes="";
								$count_indexes=0;
								while(($index=index($sequence,$string,$index))>=0)
								{
									$pre = substr $sequence,$index-5,5;
									$post = substr $sequence,$index+length($string),5;
									#print qq!$pre-$post\n!;
									if ($pre=~/^$post$/) 
									{ 
										$count_indexes++;
										$indexes.="$index,";
									}
									$index++;
								}
							}
							$count{"$db#$count_indexes"}++;
							if ($count_indexes>=1)
							{
								$name__="";
								$expect="";
								$segments_query="";
								$segments_sbjct="";
								$start_query="";
								$start_sbjct="";
								$end_query="";
								$end_sbjct="";
								$start="";
								$end="";
								$start_="";
								$end_="";
								$end_prev="";
								$end_rev_="";
								$temp=$sequence;
								$temp=~s/$string.....//g;
								if (open (OUT_,">temp.fasta"))
								{
									print OUT_ qq!>$name\n$temp\n!;
									close(OUT_);
									system(qq!"D:\\Server\\blast\\ncbi-blast-2.2.25+\\bin\\blastn" -query temp.fasta -db db/HIV1_ENV.fasta -out blast/$name.txt!);
									if (open (IN_,"blast/$name.txt"))
									{
										while($line=<IN_>)
										{
											if ($line=~/^Query=\s*(\S+)/)
											{
												$name__=$1;
											}
											if ($line=~/^\s*Score\s*=\s*([0-9\.]+)\s*bits\s*.([0-9]+).,\s*Expect\s*=\s*([0-9edED\-\+\.]+)/)
											{
												$expect=$3;
											}
											if ($line=~/^Query\s*([0-9]+)\s+(\S+)\s+([0-9]+)/)
											{
												$start=$1;
												$seq=$2;
												$end=$3;
												if ($start_query!~/\w/) { $start_query=$start; }
												if ($end_query<$end) { $end_query=$end; }
												$line=<IN_>;
												if ($line=~/^\s+(\S+)/)
												{
													$alignment=$2;
												}
												$line=<IN_>;
												if ($line=~/^Sbjct\s*([0-9]+)\s+(\S+)\s+([0-9]+)/)
												{
													$start_=$1;
													$seq_=$2;
													$end_=$3;
													if ($start_sbjct>$start) { $start_sbjct=$start_; }
													if ($end_sbjct<$end_) { $end_sbjct=$end_; }
												}
												if ($seq=~/\w/ and $seq_=~/\w/)
												{
													if ($expect=~/\w/) 
													{
														$segments_query.="$expect:"; 
														$segments_sbjct.="$expect:"; 
														$expect="";
													} 
													$segments_query.="$start-$end,";
													$segments_sbjct.="$start_-$end_,";
													$start="";
													$end="";
													$start_="";
													$end_="";
												}
											}
										}
										close(IN_);
										system(qq!del temp.fasta!);
									}
								}
								$indexes=~s/\,\s*$//;
								print qq!$name\t$name__\t$count_indexes\t$indexes\t$segments_query\t$segments_sbjct\n!;
							}
						}
			}
		}
	}
	foreach $db (@dbs)
	{
		if ($db=~/\.fasta/i)
		{
			if (open (IN,"$db_dir/$db"))
			{
				if ($count_{$db}!~/\w/) { $count_{$db}=0; }
				if ($count{$db}!~/\w/) { $count{$db}=0; }
				print qq!$db: $count_all{$db} 0:$count{"$db#0"},1:$count{"$db#1"},2:$count{"$db#2"},3:$count{"$db#3"},4:$count{"$db#4"}\n!;
				close(IN);
			}
		}
	}
}