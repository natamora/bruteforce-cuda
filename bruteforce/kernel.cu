
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <iostream>
#include <stdio.h>
#include <string>
#include <time.h>
#include <stdlib.h>
#include <windows.h>
#include "cuda.h"

#define HASH_LEN 3
//#define BENCHMARK
#define ARG_COUNT 4
//#define ALPHABET_COUNT 75
#define ALPHABET_COUNT 75
#define ALPHABET_START 48

using namespace std;

cudaError_t bruteForceWithCuda(char* hostHash, int blockCount, int threadCount);

__device__ char* devHash;
__device__ bool* stopGlobal;


static void HandleError(cudaError_t err,
	const char *file,
	int line) {
	if (err != cudaSuccess) {
		printf("%s in %s at line %d\n", cudaGetErrorString(err),
			file, line);
		exit(EXIT_FAILURE);
	}
}
#define HANDLE_ERROR( err ) (HandleError( err, __FILE__, __LINE__ ))


#define HANDLE_NULL( a ) {if (a == NULL) { \
                            printf( "Host memory failed in %s at line %d\n", \
                                    __FILE__, __LINE__ ); \
                            exit( EXIT_FAILURE );}}


__device__ bool my_strcpm(const char *string1, const char *string2, int size)
{
	for (int i = 0; i < size; i++)
	{
		if (string1[i] != string2[i])
			return false;
	}
	return true;
}

__device__ char * my_strcpy(char *dest, const char *src) {
	int i = 0;
	do {
		dest[i] = src[i];
	} while (src[i++] != 0);
	return dest;
}

__device__ char* rot(char* rotatedPassword, int rotBase, int* devHashLength)
{
	for (int i = 0; i < *devHashLength; i++)
	{
		rotatedPassword[i] = ((rotatedPassword[i] - ALPHABET_START + rotBase) % ALPHABET_COUNT) + ALPHABET_START;
	}
	return rotatedPassword;
}

__device__ char* offsetToWord(int offset, int hashSize)
{
	char sampleWord[HASH_LEN + 1];
	if (sampleWord == NULL) {
		printf("null pointer sampleword\n");
	}
	for (int i = 0; i < hashSize; i++)
	{
		sampleWord[i] = ALPHABET_START;
	}
	sampleWord[hashSize] = '\0';
	int i = hashSize - 1;
	while (offset > 0)
	{
		int x = offset % ALPHABET_COUNT;
		sampleWord[i] = ALPHABET_START + x;
		offset = offset / ALPHABET_COUNT;
		i--;
	}
	return sampleWord;
}

__global__ void addKernel(char* hashPwd, int* hashLength, bool* stopGlobal)
{
	__shared__ bool stop[1];
	stop[0] = false;

	__syncthreads();
	clock_t start = clock();
	unsigned int threadId = (blockIdx.x * blockDim.x) + threadIdx.x;
	int threadCount = blockDim.x * blockDim.y * blockDim.z * gridDim.x * gridDim.y * gridDim.z;
	int combinationCount = pow((double)ALPHABET_COUNT, (double)*hashLength);
	int combinationPerThread = ceil((double)combinationCount / (double)threadCount);
	int offset = combinationPerThread * threadId;
	char rotatedPassword[HASH_LEN + 1];
	for (int i = offset; i < offset + combinationPerThread; i++)
	{


		if (threadIdx.x == 0 && threadIdx.y == 0 && threadIdx.z == 0)
		{
			if (*stopGlobal)
			{
				stop[0] = true;
				return;
			}
			if (stop[0])
			{
				*stopGlobal = true;
				return;
			}
		}
		else 
		{
			if (stop[0])
			{
				return;
				
			}
		}
		char* sampleWord = offsetToWord(i, *hashLength);

		my_strcpy(rotatedPassword, sampleWord);

		rot(rotatedPassword, 13, hashLength);

		if (my_strcpm(rotatedPassword, hashPwd, *hashLength))
		{
			stop[0] = true;
			clock_t stop = clock();
			printf("succes: %s  offset: %d offsetWord: %s\n", rotatedPassword, offset, sampleWord);
			
		}
	}
}


int main(int argc, char* argv[])
{
	if (argc != ARG_COUNT) {
		printf("Usage ./cudaexample blockCount threadCount hashPassowrd");
		exit(1);
	}

	if (strlen(argv[ARG_COUNT - 1]) > 7) {
		printf("Too big hash size");
		exit(1);
	}
	char* hostHash = (char*)malloc(strlen(argv[ARG_COUNT-1]));
	HANDLE_NULL(hostHash);
	strcpy(hostHash, argv[ARG_COUNT - 1]);

	int blockCount = atoi(argv[1]);
	int threadCount = atoi(argv[2]);
	cudaError_t cudaStatus = bruteForceWithCuda(hostHash, blockCount, threadCount);

    return 0;
}

cudaError_t bruteForceWithCuda(char* hostHash, int blockCount, int threadCount)
{
	cudaError_t cudaStatus;
	for (int block_count = 1; block_count < 2048; block_count *= 2)
	{
	cudaStatus = cudaSetDevice(0);
	HANDLE_ERROR(cudaStatus);
	
	int* hostHashLength = (int*)malloc(sizeof(int));
	HANDLE_NULL(hostHashLength);
	*hostHashLength = strlen(hostHash);
	int* devHashLength;

	HANDLE_ERROR(cudaMalloc((void**)&devHashLength, sizeof(int)));

	HANDLE_ERROR(cudaMemcpy(devHashLength, hostHashLength, sizeof(int), cudaMemcpyHostToDevice));

	HANDLE_ERROR(cudaMalloc((void**)&devHash, strlen(hostHash)));

	HANDLE_ERROR(cudaMemcpy(devHash, hostHash, strlen(hostHash), cudaMemcpyHostToDevice));

	bool* stop = (bool*)malloc(sizeof(bool));
	HANDLE_NULL(stop);
	*stop = false;

	HANDLE_ERROR(cudaMalloc((void**)&stopGlobal, sizeof(bool)));
	HANDLE_ERROR(cudaMemcpy(stopGlobal, stop, sizeof(bool), cudaMemcpyHostToDevice));

	cudaDeviceProp deviceProperties;
	cudaGetDeviceProperties(&deviceProperties, 0);
	int max_threads;
	int max_blocks;
	max_threads = deviceProperties.maxThreadsPerBlock;


	cudaEvent_t start;
	cudaEvent_t stop1;
	HANDLE_ERROR(cudaEventCreate(&start));
	HANDLE_ERROR(cudaEventCreate(&stop1));
	HANDLE_ERROR(cudaEventRecord(start, 0));

	addKernel <<<1, block_count>>> (devHash, devHashLength, stopGlobal);

	
	HANDLE_ERROR(cudaGetLastError());

	//HANDLE_ERROR(cudaDeviceSynchronize());
	HANDLE_ERROR(cudaEventRecord(stop1, 0));
	HANDLE_ERROR(cudaEventSynchronize(stop1));
	float   elapsedTime;
	HANDLE_ERROR(cudaEventElapsedTime(&elapsedTime,
		start, stop1));
	printf("Czas generowania:  %3.1f ms ilosc blokow: %d\n", elapsedTime, block_count);

	HANDLE_ERROR(cudaEventDestroy(start));
	HANDLE_ERROR(cudaEventDestroy(stop1));

	}

	return cudaStatus;
}