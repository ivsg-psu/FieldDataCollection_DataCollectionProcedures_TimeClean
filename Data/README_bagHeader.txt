# Bag file naming
The data is stored initially and almost immediately after collection int bag files which contain the raw binary information from the PSU mapping van. They require a Python script to extract the data, usually converted (for non-image data) into CSV files so that the data processing can be done with other tools as appropriate.

The bag files have the format:

"mapping_van_YYYY-MM-DD-hh-mm-ss_N.bag"

where:

* "mapping_van" indicates the source vehicle or equipment group.

The next fields indicate the time at which the data collection started:
* YYYY is the 4-digit year
* MM is the 2-digit month
* DD is the 2-digit day of the month
* hh is the 2-digit hour of the day, on a 24 hour clock (e.g. from 00 to 23)
* mm is the 2-digit minute of the hour
* ss is the 2-digit second of the minute
Time and date is measured from the ROS time of the master data collection computer. Note that this time stamp may not be correct or in agreement with GPS time, as the ROS time on the CPU may drift slightly as would occur on many PCs. Tools exist in data processing steps (the DataClean library, specifically) that calibrate ROS time to GPS absolute time as the GPS time is provided in all GPS sensor measurements alongside ROS time.

The last field indicates the data sequence of the current run, starting at _0, then proceeding to _1, _2, etc. A test sequence is continuous in the data sense but broken up into different save files to avoid losing data if there is a catastrophic power outage or computer failure. In such a case, the last file segment may be lost or corrupted, but the segments prior to the last are nearly always saved and recoverable. There are tools within the code sets that follow that "merge" these data segments back together (again, see DataClean).

NOTE: if a bag file ends with ".active", this indicates that major failure - usually loss of power - occurred during that file's collection. The file fragment is saved, but these active files are often corrupted and not possible to process. They are kept anyway in case there is a need for such recovery, or if tools are developed later that more easily allow their processing.

# Bag file listing

