if [ `omreport storage battery | awk '{print $4}' | grep Idle` ]; then
	echo "Dell raid controller battery learn cycle is in idle state";
	exit 0;
else
	echo "Dell raid controller battery learn cycle is in non-idle state"
	exit 1;
fi
