#!/bin/bash

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

if [ $skip == false ];
	then
		#get inputs
		dx-download-all-inputs --parallel
		#get reference genome (GRCh37)
		dx cat project-ByfFPz00jy1fk6PjpZ95F27J:file-ByYgX700b80gf4ZY1GxvF3Jv | tar xzf - # ~/hs37d5.fasta-index.tar.gz -> ~/genome.fa and ~/genome.fa.fai
		mkdir ~/reference 
		mv genome.f* reference # move reference genome files to reference folder (for mounting to docker later) 

		# make output folder
		mkdir -p ~/out/sompy_output/QC

		#get the sompy docker and extract 
		sompy_docker_file_id=project-ByfFPz00jy1fk6PjpZ95F27J:file-G9ZXyyj0jy1VppkQ93ZZFqYG 
		dx download ${sompy_docker_file_id}
		sompy_Docker_image_file=$(dx describe ${sompy_docker_file_id} --name)
		sompy_Docker_image_name=$(tar xfO "${sompy_Docker_image_file}" manifest.json | sed -E 's/.*"RepoTags":\["?([^"]*)"?.*/\1/')

		docker load < /home/dnanexus/"${sompy_Docker_image_file}"

		#if TSO500 vcf need to run through bcftools before running sompy. Load docker image here so can be used for multiple files in the loop below
		if [ $TSO == true ]; #default false
			then
				echo "TSO500 run. VCF requires conversion with bcftools"
				# get bcftools docker. 
				bcftools_Docker_ID=project-ByfFPz00jy1fk6PjpZ95F27J:file-G55XqF00jy1QkJ174ZzZfzV5
				dx download ${bcftools_Docker_ID}
				bcftools_Docker_image_file=$(dx describe ${bcftools_Docker_ID} --name)
				bcftools_Docker_image_name=$(tar xfO "${bcftools_Docker_image_file}" manifest.json | sed -E 's/.*"RepoTags":\["?([^"]*)"?.*/\1/')
				docker load < /home/dnanexus/"${bcftools_Docker_image_file}"
				
		fi

		# loop through array of queryVCF input files
		for (( i=0; i<${#queryVCF_path[@]}; i++ ));
		# print the name of the vcf to be run
		do echo ${queryVCF_prefix[i]}
		#if TSO500 vcf need to run through bcftools before running sompy
		if [ $TSO == true ]; #default false
			then
				echo "TSO500 run. VCF requires conversion with bcftools"
				# get bcftools docker. 

				vcf_name=${queryVCF_name[i]%.genome.vcf*}

				echo "Using docker image ${bcftools_Docker_image_name}"
					# -e to exclude lines where ALT="." -o output name
				bcftools_output=${vcf_name}.converted.vcf
				docker run -v /home/dnanexus/in/queryVCF/$i:/query -v /home/dnanexus/out/sompy_output/QC:/output --rm ${bcftools_Docker_image_name} view -e 'ALT="."' -o /output/${bcftools_output} /query/${queryVCF_name[i]}
				
		fi

		#run sompy. Different commands for varscan (additional output information available) and TSO runs (different input vcf, using one created with bcftools above)
		echo "Using docker image ${sompy_Docker_image_name}"

		if [ $varscan == true ]; #default false
			then
			sudo docker run -v /home/dnanexus/in/truthVCF:/truth -v /home/dnanexus/in/queryVCF/$i:/query -v /home/dnanexus/reference:/reference -v /home/dnanexus/out/sompy_output/QC:/output --rm ${sompy_Docker_image_name} /opt/hap.py/bin/som.py /truth/${truthVCF_name} /query/${queryVCF_name[i]} -r /reference/genome.fa --feature-table hcc.varscan2.snv -o /output/${queryVCF_name[i]}	

		elif [ $TSO == true ]; #default false, if TSO need to use bcftools modified vcf as query (in output folder)
			then
			sudo docker run -v /home/dnanexus/in/truthVCF:/truth -v /home/dnanexus/reference:/reference -v /home/dnanexus/out/sompy_output/QC:/output --rm ${sompy_Docker_image_name} /opt/hap.py/bin/som.py /truth/${truthVCF_name} /output/${bcftools_output} -r /reference/genome.fa -o /output/${queryVCF_name[i]}	

		else
			sudo docker run -v /home/dnanexus/in/truthVCF:/truth -v /home/dnanexus/in/queryVCF/$i:/query -v /home/dnanexus/reference:/reference -v /home/dnanexus/out/sompy_output/QC:/output --rm ${sompy_Docker_image_name} /opt/hap.py/bin/som.py /truth/${truthVCF_name} /query/${queryVCF_name[i]} -r /reference/genome.fa -o /output/${queryVCF_name[i]}	
		fi
		done
		#send output back to DNANexus
		dx-upload-all-outputs --parallel

fi