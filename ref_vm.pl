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
			$regs->{flags} |= $flag_masks->{greater} if $stack[$regs->{sp}] > $_[2];
			$regs->{flags} |= $flag_masks->{equal} if $stack[$regs->{sp}] == $_[2];
			$regs->{ip} += 4;
		}
	}
);

my @code = (
	0x05, 0x02, 0x01, 0x00,
	#cmp r0, r1
	0x11, 0x02, 0x03, 0x00,
	#cmp r0, 0x01
	0x10, 0x02, 0x01, 0x00,
	#htl
	0x00, 0x00, 0x00, 0x00
);

#Load code to stack
@stack[0 .. scalar @code - 1] = @code;

#While we are running...
while($regs->{state}){
	print_regs();

	#Fetch/decode new instruction
	my $opt_code = $stack[$regs->{ip}];
	$opts[$opt_code]->{opt}->(@stack[$regs->{ip} .. $regs->{ip} + 4]);
}

sub print_regs{
	printf(
		"ip: %x  sp: %x  r0: %x  r1: %x  fl: %.5b\t", 
		$regs->{ip},
		$regs->{sp},
		$regs->{r0},
		$regs->{r1},
		$regs->{flags}
	);

	print join(" ", map { sprintf("%.2x", $_) } @stack[0 .. 25])."\n";
}