#!/bin/bash
about () {
	echo ""
	echo "  ========================================================= "
	echo "  \             Serverreview Benchmark Script             / "
	echo "  \       Basic system info, I/O test and speedtest       / "
	echo "  \                V 2.2.3  (09 Apr 2016)                   / "
	echo "  \             Created by Sayem Chowdhury                / "
	echo "  ========================================================= "
	echo ""
	echo "  This script is based on bench.sh by camarg from akamaras.com"
	echo "  Later it was modified by dmmcintyre3 on FreeVPS.us"
	echo "  Thanks to Hidden_Refuge for the update of this script"
	echo ""
}
prms () {
	echo "  $(tput setaf 3)-info$(tput sgr0)          - Check basic system information"
	echo "  $(tput setaf 3)-io$(tput sgr0)            - Run I/O test with or w/ cache"
	echo "  $(tput setaf 3)-cdn$(tput sgr0)           - Check download speed from CDN"
	echo "  $(tput setaf 3)-northamercia$(tput sgr0)  - Download speed from North America"
	echo "  $(tput setaf 3)-europe$(tput sgr0)        - Download speed from Europe"
	echo "  $(tput setaf 3)-asia$(tput sgr0)          - Download speed from asia"
	echo "  $(tput setaf 3)-a$(tput sgr0)             - Test and check all above things at once"
	echo "  $(tput setaf 3)-b$(tput sgr0)             - System info, CDN speedtest and I/O test"
	echo "  $(tput setaf 3)-ispeed$(tput sgr0)        - Install speedtest-cli (python 2.4-3.4 required)"
	echo "  $(tput setaf 3)-speed$(tput sgr0)         - Check internet speed using speedtest-cli"
	echo "  $(tput setaf 3)-about$(tput sgr0)         - Check about this script"
	echo ""
}
howto () {
	echo "Wrong parameters. Use $(tput setaf 3)bash bench -help$(tput sgr0) to see parameters"
	echo "ex: $(tput setaf 3)bash bench -info$(tput sgr0) (without quotes) for system information"
	echo ""
}
systeminfo () {
	hostname=$( hostname )
	cpumodel=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
	cpubits=$( uname -m )
	kernel=$( uname -r )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo )
	freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
	tram=$( free -h | grep Mem | awk 'NR=1 {print $2}' )B
	fram=$( free -h | grep Mem | awk 'NR=1 {print $4}' )B
	hdd=$( df -h --total | grep 'total' | awk '{print $2}' )B
	hddfree=$( df -h --total | grep 'total' | awk '{print $5}' )
	tswap=$( free -h | grep Swap | awk 'NR=1 {print $2}' )B
	tswap0=$( cat /proc/meminfo | grep SwapTotal | awk 'NR=1 {print $2$3}' )
	fswap=$( free -h | grep Swap | awk 'NR=1 {print $4}' )B
	uptime=$( awk '{print int($1/86400)"days - "int($1%86400/3600)"hrs "int(($1%3600)/60)"min "int($1%60)"sec"}' /proc/uptime )
	# Systeminfo
	echo ""
	echo " $(tput setaf 6)##System Information$(tput sgr0)"
	echo ""
	# OS Information (Name)
	if [ "$cpubits" == 'x86_64' ]; then
	bits=" (64 bit)"
	else
	bits=" (32 bit)"
	fi
	if hash lsb_release 2>/dev/null; 
	then
	soalt=`lsb_release -d`
	echo -e " OS Name:    "${soalt:13} $bits
	else
	so=`cat /etc/issue`
	pos=`expr index "$so" 123456789`
	so=${so/\/}
	extra=""
	if [[ "$so" == Debian*6* ]]; 
	then
	extra="(squeeze)"
	fi
	if [[ "$so" == Debian*7* ]]; 
	then
	extra="(wheezy)"
	fi
	if [[ "$so" == *Proxmox* ]]; 
	then
	so="Debian 7.6 (wheezy)";
	fi
	otro=`expr index "$so" \S`
	if [[ "$otro" == 2 ]]; 
	then
	so=`cat /etc/*-release`
	pos=`expr index "$so" NAME`
	pos=$((pos-2))
	so=${so/\/}
	fi
	echo -e " OS Name:    "${so:0:($pos+2)} $extra$bits
	fi
	sleep 0.1
	#Detect virtualization
	if hash ifconfig 2>/dev/null; then
	eth=`ifconfig`
	fi
	virtualx=`dmesg`
	if [[ "$eth" == *eth0* ]]; 
	then
	virtual="Dedicated"
	elif [[ "$virtualx" == *kvm-clock* ]]; 
	then
	virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; 
	then
	virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; 
	then
	virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; 
	then
	virtual="VirtualBox"
	elif [ -f /proc/user_beancounters ]
	then
	virtual="OpenVZ"
	elif [ -e /proc/xen ]
	then
	virtual="Xen"
	fi
	#Kernel
	echo " Kernel:     $virtual / $kernel"
	sleep 0.1
	# Hostname
	echo " Hostname:   $hostname"
	sleep 0.1
	# CPU Model Name
	echo " CPU Model: $cpumodel"
	sleep 0.1
	# Cpu Cores
	if [ $cores=1 ]
	then
	echo " CPU Cores:  $cores core @ $freq MHz"
	else
	echo " CPU Cores:  $cores cores @ $freq MHz"
	fi
	sleep 0.1
	echo " CPU Cache: $corescache"
	sleep 0.1
	# Ram Information
	echo " Total RAM:  $tram (Free $fram)"
	sleep 0.1
	# Swap Information
	if [ "$tswap0" = '0kB' ]
	then
	echo " Total SWAP: SWAP not enabled"
	else
	echo " Total SWAP: $tswap (Free $fswap)"
	fi
	sleep 0.1
	echo " Total Space: $hdd ($hddfree used)"
	sleep 0.1
	# Uptime
	echo " Running for: $uptime"
	echo ""
}
cdnspeedtest () {
	echo ""
	echo " $(tput setaf 6)##CDN Speedtest$(tput sgr0)"
	cachefly=$( wget -O /dev/null http://cachefly.cachefly.net/100mb.test 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' ); echo " CacheFly:  $cachefly"
	cacheflyping=$( ping -c3 cachefly.cachefly.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $cacheflyping ms";
	
	internode=$( wget -O /dev/null http://speedcheck.cdn.on.net/100meg.test 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' ); echo " Internode: $internode"
	pinghost=$( ping -c3 speedcheck.cdn.on.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	echo ""
}
northamerciaspeedtest () {
	echo ""
	echo " $(tput setaf 6)##North America Speedtest$(tput sgr0)"
	nas1=$( wget -O /dev/null http://speedtest.dal01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " SoftLayer, Dallas, USA: $nas1"
	pinghost=$( ping -c3 speedtest.dal01.softlayer.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";

	nas2=$( wget -O /dev/null http://speedtest.choopa.net/100MBtest.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " ReliableSite, Piscataway, USA: $nas2"
	pinghost=$( ping -c3 speedtest.choopa.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	nas3=$( wget -O /dev/null http://bhs.proof.ovh.net/files/100Mio.dat 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " OVH, Beauharnois, Canada: $nas3"
	pinghost=$( ping -c3 bhs.proof.ovh.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	nas4=$( wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Softlayer, Washington, USA: $nas4"
	pinghost=$( ping -c3 speedtest.wdc01.softlayer.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	nas5=$( wget -O /dev/null http://speedtest.sjc01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " SoftLayer, San Jose, USA: $nas5"
	pinghost=$( ping -c3 speedtest.sjc01.softlayer.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	nas6=$( wget -O /dev/null http://tx-us-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Dallas, USA: $nas6"
	pinghost=$( ping -c3 tx-us-ping.vultr.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	nas7=$( wget -O /dev/null http://nj-us-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, New Jersey, USA: $nas7"
	pinghost=$( ping -c3 nj-us-ping.vultr.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	nas8=$( wget -O /dev/null http://wa-us-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Seattle, USA: $nas8"
	pinghost=$( ping -c3 wa-us-ping.vultr.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	echo ""
}
europespeedtest () {
	echo ""
	echo " $(tput setaf 6)##Europe Speedtest$(tput sgr0)"
	es1=$( wget -O /dev/null http://149.3.140.170/100.log 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " RedStation, Gosport, UK: $es1"
	pinghost=$( ping -c3 149.3.140.170 | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	es2=$( wget -O /dev/null http://se.edis.at/100MB.test 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " EDIS, Stockholm, Sweden: $es2"
	pinghost=$( ping -c3 se.edis.at | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	es3=$( wget -O /dev/null http://rbx.proof.ovh.net/files/100Mio.dat 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " OVH, Roubaix, France: $es3"
	pinghost=$( ping -c3 rbx.proof.ovh.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	es5=$( wget -O /dev/null http://mirrors.prometeus.net/test/test100.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Prometeus, Milan, Italy: $es5"
	pinghost=$( ping -c3 mirrors.prometeus.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	es6=$( wget -O /dev/null http://mirror.de.leaseweb.net/speedtest/100mb.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " LeaseWeb, Frankfurt, Germany: $es6"
	pinghost=$( ping -c3 mirror.de.leaseweb.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	es7=$( wget -O /dev/null http://mirror.i3d.net/100mb.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Interactive3D, Amsterdam, NL: $es7"
	pinghost=$( ping -c3 mirror.i3d.net | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	es8=$( wget -O /dev/null http://lon-gb-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, London, UK: $es8"
	pinghost=$( ping -c3 lon-gb-ping.vultr.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	es9=$( wget -O /dev/null http://ams-nl-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Amsterdam, NL: $es9"
	pinghost=$( ping -c3 ams-nl-ping.vultr.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	echo ""
}
asiaspeedtest () {
	echo ""
	echo " $(tput setaf 6)##Asia Speedtest$(tput sgr0)"
	as1=$( wget -O /dev/null http://speedtest.sng01.softlayer.com/downloads/test100.zip 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " SoftLayer, Singapore, Singapore $as1"
	pinghost=$( ping -c3 speedtest.sng01.softlayer.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	as2=$( wget -O /dev/null http://speedtest.singapore.linode.com/100MB-singapore.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Linode, Singapore, Singapore $as2"
	pinghost=$( ping -c3 speedtest.singapore.linode.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	as3=$( wget -O /dev/null http://speedtest.tokyo.linode.com/100MB-tokyo.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Linode, Tokyo, Japan: $as3"
	pinghost=$( ping -c3 speedtest.tokyo.linode.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	as4=$( wget -O /dev/null http://hnd-jp-ping.vultr.com/vultr.com.100MB.bin 2>&1 | awk '/\/dev\/null/ {speed=$3 $4} END {gsub(/\(|\)/,"",speed); print speed}' )
	echo " Vultr, Tokyo, Japan: $as4"
	pinghost=$( ping -c3 hnd-jp-ping.vultr.com | grep 'rtt' | cut -d"/" -f5 ); echo " Latency: $pinghost ms";
	
	echo ""
}
iotest () {
	echo ""
	echo " $(tput setaf 6)##IO Test$(tput sgr0)"
	io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync && rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo " I/O Speed : $io"
	io=$( ( dd if=/dev/zero of=test bs=64k count=16k conv=fdatasync oflag=direct && rm -f test ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
	echo " I/O Direct : $io"
	echo ""
}
installspeedtest () {
	# Installing speed test
	wget -q --no-check-certificate https://raw.github.com/sivel/speedtest-cli/master/speedtest_cli.py && chmod a+rx speedtest_cli.py && mv speedtest_cli.py /usr/local/bin/speedtest-cli && chown root:root /usr/local/bin/speedtest-cli
	echo " Installing speedtest-cli script has been finished"
	echo " speedtest-cli works with Python 2.4-3.4"
	echo " You do not need to run this second time"
	echo " Run 'bash bench -speed' to run speedtest" | sed $'s/bash bench -speed/\e[1m&\e[0m/'
	echo ""
}
speedtestresults () {
	#Testing Speedtest
	speedtest-cli --share
	echo ""
}
case $1 in
	'-info'|'-information'|'--info'|'--information' )
		systeminfo;;
	'-io'|'-drivespeed'|'--io'|'--drivespeed' )
		iotest;;
	'-northamercia'|'-na'|'--northamercia'|'--na' )
		northamerciaspeedtest;;
	'-europe'|'-eu'|'--europe'|'--eu' )
		europespeedtest;;
	'-asia'|'--asia' )
		asiaspeedtest;;
	'-cdn'|'--cdn' )
		cdnspeedtest;;
	'-b'|'--b' )
		systeminfo; cdnspeedtest; iotest;;
	'-a'|'-all'|'-bench'|'--a'|'--all'|'--bench' )
		systeminfo; cdnspeedtest; northamerciaspeedtest; europespeedtest; asiaspeedtest; iotest;;
	'-ispeed'|'-installspeed'|'-installspeedtest'|'--ispeed'|'--installspeed'|'--installspeedtest' )
		installspeedtest;;
	'-speed'|'-speedtest'|'-speedcheck'|'--speed'|'--speedtest'|'--speedcheck' )
		speedtestresults;;
	'-help'|'--help' )
		prms;;
	'-about'|'--about' )
		about;;
	*)
		howto;;
esac
