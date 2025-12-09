# compiles form_fact library into an executable

# compiler  
# TODO: these should be arguments passed by a "master" makefile or bash script
FC 		= gfortran
CFLAGS 	= -g 
COPTS   = -O3 # highest level - change to -O2 or even -O1 if too slow

all: check
	fpm build
	fpm run form_fact
	fpm install

# check if f_0.f90 and f1_f2.f90 are present; if they are not, build them
check:
	@if [ ! -f "src/f0.f90" ]; then \
		$(MAKE) -f Parse-F0.mk ; \
	fi
	@if [ ! -f "src/f1_f2.f90" ]; then \
		$(MAKE) -f Parse-F1_F2.mk ; \
	fi
