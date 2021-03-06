#!/bin/bash

# script with preprocessing, stan, and non_morpho_plot dictionaries
# will be copied before modifying, so the original script will be unchanged.
# The copy will be deleted when this script is done.
yaml_script=./scripts/example_ricochet_rate_spec_analyzer.yaml
yaml_script_copy=./scripts/temp_rate_spec_60pctOn_example_ricochet_rate_spec_analyzer.yaml

# Replace all instances of init_descriptor with new_descriptor in
# the .yaml script
init_descriptor='ric_rate_spec_example'
new_descriptor='example_ric_rate_spec_60pctOn'

# Folder to store plots and tables from the runs
results_folder=\"'./results/'$new_descriptor'plots/'\"

# signal rates, backgrounds rates, and run times to iterate over
signals='5'
backgrounds='15 36 50'
times='365 1825'

# bins_per_year and times must be integers
bins_per_year='50'

# Function for the signal rate as a function of time
rate_cns_fcn='cns_time'
# Parameters: [full_power_frac,off_frac,force_fractions,
#              correlate_bins,correlate_days,fluctuation_frac]
rate_cns_params='[0.6,0.0,True,True,40,0.05]'
#rate_cns_fcn='cns_time_onillon'
#rate_cns_params='[]'

sig_bin_var=0.05
sig_global_var=0.0
total_bin_var=0.15

# stan model
stan_model=\"'binned_data_analysis_2D_4back_tot_bin_var'\"
stan_model_file=\"'./models/binned_data_analysis_2D_4back_tot_bin_var.stan'\"
#stan_model=\"'binned_data_analysis_2D_1back'\"
#stan_model_file=\"'./models/binned_data_analysis_2D_1back.stan'\"

flat_flat_weight=11.6
H3_weight=3.7

# Run Number to be saved on the end of 
runNumber=""
# runNumber can be iterated, to repeat the same test multiple times
#for runNumber in {1..100}; do
#runNumber=$runNumber'_'

# Location of the virtual environment activation script
virtualenv_script='../venv/bin/activate'

# -----------------------------------------------------------------------------
. $virtualenv_script

if [[ -z $bins_per_year ]]; then
    bins_per_year='30'
fi

if [[ -z $yaml_script_copy ]]; then
    yaml_script_copy=$yaml_script'_copy'
fi
cp $yaml_script $yaml_script_copy

sed -i 's/'$init_descriptor'/'$new_descriptor'/g' $yaml_script_copy

# This tag is on the end of elements in indep_vars and dimension_params that should be changed
tag='Time'

sed -i 's/\(.*fcn_name: \).*\( # '$tag' Sig\)/\1'$rate_cns_fcn'\2/' $yaml_script_copy
sed -i 's/\(.*params: \).*\( # '$tag' Sig\)/\1'$rate_cns_params'\2/' $yaml_script_copy

sed -i 's/\(.*name: \).*\( # Stan\)/\1'$stan_model'\2/' $yaml_script_copy
sed -i 's@\(.*file: \).*\( # Stan\)@\1'$stan_model_file'\2@' $yaml_script_copy

sed -i 's/\(.*bin_gauss_var_frac: \).*\( # '$tag' Sig\)/\1'$sig_bin_var'\2/' $yaml_script_copy
sed -i 's/\(.*global_gauss_var_frac: \).*\( # '$tag' Sig\)/\1'$sig_global_var'\2/' $yaml_script_copy
sed -i 's/\(.*bin_gauss_var_total: \).*/\1'$total_bin_var'/' $yaml_script_copy

sed -i 's/\(.*fake_data_weight: \).*\( # Flat Flat\)/\1'$flat_flat_weight'\2/' $yaml_script_copy
sed -i 's/\(.*fake_data_weight: \).*\( # H3\)/\1'$H3_weight'\2/' $yaml_script_copy

for time in $times; do
for signal in $signals; do
for background in $backgrounds; do
    sed -i 's/\(.*upper_bound: \).*\( # '$tag'\)/\1'$time'\2/' $yaml_script_copy
    sed -i 's/\(.*fake_signal_magnitude: \).*/\1'$signal'/' $yaml_script_copy
    sed -i 's/\(.*fake_background_magnitude: \).*/\1'$background'/' $yaml_script_copy
    output_prefix="\"sig_"$signal"_back_"$background"_time_"$time"_"$runNumber\"
    sed -i 's/\(.*plots_output_prefix: \).*/\1'$output_prefix'/' $yaml_script_copy
    title_postfix="Sig="$signal',Back='$background',Time='$time
    sed -i 's/\(.*title_postfix: \).*/\1'$title_postfix'/' $yaml_script_copy
    sed -i 's#\(.*plots_output_directory: \).*#\1'$results_folder'#' $yaml_script_copy

    exp=$bins_per_year'*'$time'/365'
    bins=$((exp))
    sed -i 's/\(.*bins: \).*\( # '$tag'\)/\1'$bins'\2/' $yaml_script_copy

    python helper_scripts/shape_fakedata_generator.py -c $yaml_script_copy
    morpho -c $yaml_script_copy
    python ./helper_scripts/non_morpho_plots.py -c $yaml_script_copy
done
done
done
#done

rm $yaml_script_copy
