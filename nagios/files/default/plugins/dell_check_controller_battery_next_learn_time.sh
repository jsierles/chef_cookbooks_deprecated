if [ `omreport storage battery | grep "Next Learn Time" | grep ": 0 days"` ]; then
	echo "Next Dell raid controller battery learn cycle is in < 1day!"
	exit 1;
else
	echo "Next Dell raid controller battery learn cycle is in more than 1 day";
	exit 0;
fi
