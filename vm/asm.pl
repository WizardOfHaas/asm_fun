#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my $regs = {
	ip => 0,
	sp => 1,
	r0 => 2,
	r1 => 3
};

my $opts = {
	"hlt"				=> 0,

	"push const" 		=> 1,
	"push reg" 			=> 2,

	"pop reg" 			=> 3,

	"mov const"		 	=> 4,
	"mov reg const"		=> 5,
	"mov reg reg"		=> 6,
	"mov reg"			=> 7,

	"add reg const"		=> 8,
	"add reg reg"		=> 9,
	"add const"			=> 10,
	"add reg"			=> 11,

	"sub reg const"		=> 12,
	"sub reg reg"		=> 13,
	"sub const"			=> 14,
	"sub reg"			=> 15,

	"cmp reg const"		=> 17,
	"cmp reg reg"		=> 18,
	"cmp reg"			=> 19,
	"cmp const"			=> 20,

	"jmp const"			=> 21,
	"jmp reg"			=> 22,
	"jmp"				=> 23,

	"je const"			=> 25,
	"je reg"			=> 26,
	"je"				=> 27,

	"jne const"			=> 29,
	"jne reg"			=> 30,
	"jne"				=> 31,

	"jg const"			=> 33,
	"jg reg"			=> 34,
	"jg"				=> 35,

	"jl const"			=> 37,
	"jl reg"			=> 38,
	"jl"				=> 39,

	"jo const"			=> 41,
	"jo reg"			=> 42,
	"jo"				=> 43,

	"jerr const"		=> 45,
	"jerr reg"			=> 46,
	"jerr"				=> 47,

	"clf"				=> 49,
	"stf"				=> 50,

	"rd reg const"		=> 52,
	"rd reg reg"		=> 53,
	"rd reg"			=> 54,
	"rd const"			=> 55,

	"wr reg const"		=> 57,
	"wr reg reg"		=> 58,
	"wr reg"			=> 59,
	"wr const"			=> 60,
};

open my $fh, "<", $ARGV[0];
open my $out, ">:raw", $ARGV[0].".bin";

my $labels = {};

my $address = 0;
my @code;

while(<$fh>){
	#Clean-up line
	$_ =~ s/\t|,//g;
	chomp;

	my @tokens = split(/ /, $_); #Split to tokens

	next if(scalar @tokens < 1 || $tokens[0] =~ m/^#/);

	if($tokens[0] =~ m/:$/){ #Do we have a label?
		$tokens[0] =~ s/://;
		$labels->{$tokens[0]} = $address; #Store label address
		next;
	}

	if($tokens[0] eq 'b'){
		#Do define bytes
		foreach my $d(@tokens[1 .. scalar @tokens]){
			if(defined $d){
				push(@code, convert_const($d));
				$address++;
			}
		}

		next;
	}

	my $mode = "";
	my @op = (0, 0, 0, 0);

	print $tokens[0]."\t";

	if(defined $tokens[1] && $tokens[1] =~ m/(ip|sp|r0|r1)/){
		print $regs->{$tokens[1]}."\t";
		$mode .= " reg";
		$op[1] = $regs->{$tokens[1]};
	}elsif(defined $tokens[1]){
		print $tokens[1]."\t";
		$mode .= " const";
		$op[1] = convert_const($tokens[1]);
	}

	if(defined $tokens[2] && $tokens[2] =~ m/(ip|sp|r0|r1)/){
		print $regs->{$tokens[2]};
		$mode .= " reg";
		$op[2] = $regs->{$tokens[2]};
	}elsif(defined $tokens[2]){
		print $tokens[2];
		$mode .= " const";
		$op[2] = convert_const($tokens[2]);
	}

	my $op_id = $tokens[0].$mode;

	if(defined $opts->{$op_id}){
		$op[0] = $opts->{$op_id};
	}else{
		die "Invalid operation:\n\t$op_id\n";
	}

	print "\t\t".$op_id."\n";

	push(@code, @op);
	$address += 4;
}

foreach my $byte(@code){
	#Apply lasbels
	if(defined $byte && $byte =~ m/[a-z]/){
		die "$byte not defined" unless defined $labels->{$byte};
		$byte = $labels->{$byte};
	}

	print $out pack('C', $byte) if defined $byte;
}

sub convert_const{
	my ($c) = @_;

	if($c =~ m/['"](.+)['"]/){
		$c = ord($1);
	}

	return $c;
}