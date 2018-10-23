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

	"jmp reg"			=> 21,
	"jmp const"			=> 22,
	"jmp"				=> 23,

	"je reg"			=> 25,
	"je const"			=> 26,
	"je"				=> 27,

	"jne reg"			=> 29,
	"jne const"			=> 30,
	"jne"				=> 31,

	"jg reg"			=> 33,
	"jg const"			=> 34,
	"jg"				=> 35,
	
	"jl reg"			=> 37,
	"jl const"			=> 38,
	"jl"				=> 39
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

	my $mode = "";
	my @op = (0, 0, 0, 0);

	print $tokens[0]."\t";

	if(defined $tokens[1] && $tokens[1] =~ m/(ip|sp|r0|r1)/){
		print $regs->{$tokens[1]}."\t";
		$mode .= "reg";
		$op[1] = $regs->{$tokens[1]};
	}elsif(defined $tokens[1]){
		print $tokens[1]."\t";
		$mode .= "const";
		$op[1] = $tokens[1];
	}

	if(defined $tokens[2] && $tokens[2] =~ m/(ip|sp|r0|r1)/){
		print $regs->{$tokens[2]};
		$mode .= " reg";
		$op[2] = $regs->{$tokens[2]};
	}elsif(defined $tokens[2]){
		print $tokens[2];
		$mode .= " const";
		$op[2] = $tokens[2];
	}

	my $op_id = $tokens[0]." ".$mode;
	$op[0] = $opts->{$op_id};

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