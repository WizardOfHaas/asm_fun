#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my $regs = {
	ip => 0,
	sp => 0,
	r0 => 0,
	r1 => 0,
	flags => 0,
	state => 1
};

my @reg_ids = (
	"ip",
	"sp",
	"r0",
	"r1"
);

my $flag_masks = {
	zero => 	0b00001,
	greater =>  0b00010,
	equal => 	0b00100,
	overflow =>	0b01000,
	error => 	0b10000
};

my @stack = (0) x 1024;

my @opts = (
	{	#0x00
		name => "hlt",
		opt => sub {
			$regs->{state} = 0;
		}
	},{	#0x01
		name => "push const",
		opt => sub {
			$stack[$regs->{sp}] = $_[1];
			$regs->{sp}++;
			$regs->{ip} += 4;
		}
	},{	#0x02
		name => "push reg",
		opt => sub {
			$stack[$regs->{sp}] = $regs->{$reg_ids[$_[1]]};
			$regs->{sp}++;
			$regs->{ip} += 4;
		}
	},{	#0x03
		name => "pop reg",
		opt => sub {
			$regs->{sp}--;
			$regs->{$reg_ids[$_[1]]} = $stack[$regs->{sp}];
			$regs->{ip} += 4;
		}
	},{ #0x04
		name => "mov reg to stack",
		opt => sub {
			$stack[$regs->{sp}] = $_[1];
			$regs->{ip} += 4;
		}
	},{ #0x05
		name => "mov const to reg",
		opt => sub {
			$regs->{$reg_ids[$_[1]]} = $_[2];
			$regs->{ip} += 4;
		}
	},{ #0x06
		name => "mov reg to reg",
		opt => sub {
			$regs->{$reg_ids[$_[1]]} = $regs->{$reg_ids[$_[2]]};
			$regs->{ip} += 4;
		}
	},{ #0x07
		name => "mov reg to stack",
		opt => sub {
			$stack[$regs->{sp}] = $regs->{$reg_ids[$_[1]]};
			$regs->{ip} += 4;
		}
	},{ #0x08
		name => "add const to reg",
		opt => sub {
			$regs->{$reg_ids[$_[1]]} += $_[2];
			$regs->{ip} += 4;
		}
	},{ #0x09
		name => "add reg to reg",
		opt => sub {
			$regs->{$reg_ids[$_[1]]} += $regs->{$reg_ids[$_[2]]};
			$regs->{ip} += 4;
		}
	},{ #0x0A
		name => "add const to stack",
		opt => sub {
			$stack[$regs->{sp}] += $_[1];
			$regs->{ip} += 4;
		}
	},{ #0x0B
		name => "add reg to stack",
		opt => sub {
			$stack[$regs->{sp}] += $regs->{$reg_ids[$_[1]]};
			$regs->{ip} += 4;
		}
	},{ #0x0C
		name => "sub const from reg",
		opt => sub {
			$regs->{$reg_ids[$_[1]]} -= $_[2];
			$regs->{ip} += 4;
		}
	},{ #0x0D
		name => "sub reg from reg",
		opt => sub {
			$regs->{$reg_ids[$_[1]]} -= $regs->{$reg_ids[$_[2]]};
			$regs->{ip} += 4;
		}
	},{ #0x0E
		name => "sub const from stack",
		opt => sub {
			$stack[$regs->{sp}] -= $_[1];
			$regs->{ip} += 4;
		}
	},{ #0x0F
		name => "sub reg from stack",
		opt => sub {
			$stack[$regs->{sp}] -= $regs->{$reg_ids[$_[1]]};
			$regs->{ip} += 4;
		}
	},{	#0x10
		name => "cmp reg to const",
		opt => sub {
			$regs->{flags} = 0;
			$regs->{flags} |= $flag_masks->{zero} if $regs->{$reg_ids[$_[1]]} == 0;
			$regs->{flags} |= $flag_masks->{greater} if $regs->{$reg_ids[$_[1]]} > $_[2];
			$regs->{flags} |= $flag_masks->{equal} if $regs->{$reg_ids[$_[1]]} == $_[2];
			$regs->{ip} += 4;
		}
	},{	#0x11
		name => "cmp reg to reg",
		opt => sub {
			$regs->{flags} = 0;
			$regs->{flags} |= $flag_masks->{zero} if $regs->{$reg_ids[$_[1]]} == 0;
			$regs->{flags} |= $flag_masks->{greater} if $regs->{$reg_ids[$_[1]]} > $regs->{$reg_ids[$_[2]]};
			$regs->{flags} |= $flag_masks->{equal} if $regs->{$reg_ids[$_[1]]} == $regs->{$reg_ids[$_[2]]};
			$regs->{ip} += 4;
		}
	},{	#0x12
		name => "cmp reg to stack",
		opt => sub {
			$regs->{flags} = 0;
			$regs->{flags} |= $flag_masks->{zero} if $stack[$regs->{sp}] == 0;
			$regs->{flags} |= $flag_masks->{greater} if $stack[$regs->{sp}] > $regs->{$reg_ids[$_[1]]};
			$regs->{flags} |= $flag_masks->{equal} if $stack[$regs->{sp}] == $regs->{$reg_ids[$_[1]]};
			$regs->{ip} += 4;
		}
	},{	#0x13
		name => "cmp const to stack",
		opt => sub {
			$regs->{flags} = 0;
			$regs->{flags} |= $flag_masks->{zero} if $stack[$regs->{sp}] == 0;
			$regs->{flags} |= $flag_masks->{greater} if $stack[$regs->{sp}] > $_[1];
			$regs->{flags} |= $flag_masks->{equal} if $stack[$regs->{sp}] == $_[1];
			$regs->{ip} += 4;
		}
	},{ #0x14
		name => "jmp to const",
		opt => sub {
			$regs->{ip} = $_[1];
		}
	},{ #0x15
		name => "jmp to reg",
		opt => sub {
			$regs->{ip} = $regs->{$reg_ids[$_[1]]};
		}
	},{ #0x16
		name => "jmp to stack",
		opt => sub {
			$regs->{ip} = $stack[$regs->{sp}];
		}
	},{ #0x17
		name => "je to const",
		opt => sub {
			if($regs->{flags} & $flag_masks->{equal}){
				$regs->{ip} = $_[1];
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x18
		name => "je to reg",
		opt => sub {
			if($regs->{flags} & $flag_masks->{equal}){
				$regs->{ip} = $regs->{$reg_ids[$_[1]]};;
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x19
		name => "je to stack",
		opt => sub {
			if($regs->{flags} & $flag_masks->{equal}){
				$regs->{ip} = $stack[$regs->{sp}];
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x1A
		name => "jne to const",
		opt => sub {
			if(!($regs->{flags} & $flag_masks->{equal})){
				$regs->{ip} = $_[1];
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x1B
		name => "jne to reg",
		opt => sub {
			if(!($regs->{flags} & $flag_masks->{equal})){
				$regs->{ip} = $regs->{$reg_ids[$_[1]]};;
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x1C
		name => "jne to stack",
		opt => sub {
			if(!($regs->{flags} & $flag_masks->{equal})){
				$regs->{ip} = $stack[$regs->{sp}];
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x1D
		name => "jg to const",
		opt => sub {
			if($regs->{flags} & $flag_masks->{greater}){
				$regs->{ip} = $_[1];
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x1E
		name => "jg to reg",
		opt => sub {
			if($regs->{flags} & $flag_masks->{greater}){
				$regs->{ip} = $regs->{$reg_ids[$_[1]]};;
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x1F
		name => "jg to stack",
		opt => sub {
			if($regs->{flags} & $flag_masks->{greater}){
				$regs->{ip} = $stack[$regs->{sp}];
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x20
		name => "jl to const",
		opt => sub {
			if(!($regs->{flags} & $flag_masks->{greater})){
				$regs->{ip} = $_[1];
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x21
		name => "jl to reg",
		opt => sub {
			if(!($regs->{flags} & $flag_masks->{greater})){
				$regs->{ip} = $regs->{$reg_ids[$_[1]]};;
			}else{
				$regs->{ip} += 4;
			}
		}
	},{ #0x22
		name => "jl to stack",
		opt => sub {
			if(!($regs->{flags} & $flag_masks->{greater})){
				$regs->{ip} = $stack[$regs->{sp}];
			}else{
				$regs->{ip} += 4;
			}
		}
	}
);

my @code = (
	0x08, 0x02, 0x01, 0x00,	#mov r0, 0x04
	0x10, 0x02, 0x0A, 0x00,	#cmp r0, ##
	0x1A, 0x00, 0x00, 0x00, #je 0x10
	0x00, 0x00, 0x00, 0x00	#hlt
);

#Load code to stack
@stack[0 .. scalar @code - 1] = @code;

#Get ready to output
`rm -rf /tmp/vm_log`;
open my $out, ">", "/tmp/vm_log" or die $!;

#While we are running...
while($regs->{state}){
	#Output reg and stack data
	print_regs();

	#Fetch/decode new instruction
	my $opt_code = $stack[$regs->{ip}];
	print $opts[$opt_code]->{name}."\n";
	$opts[$opt_code]->{opt}->(@stack[$regs->{ip} .. $regs->{ip} + 4]);
}

sub print_regs{
	my $msg = sprintf(
		"ip: %.2x  sp: %.2x  r0: %.2x  r1: %.2x  fl: %.5b\t", 
		$regs->{ip},
		$regs->{sp},
		$regs->{r0},
		$regs->{r1},
		$regs->{flags}
	).
	join(" ", map { sprintf("%.2x", $_) } @stack[0 .. 50])."\n";

	print $out $msg;
}