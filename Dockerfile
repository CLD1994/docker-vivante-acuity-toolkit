ARG CUDA_IMAGE_NAME
ARG TARGET_DEVICE

FROM busybox as unzipper

COPY ./V853_NPU_Toolkits.zip .

RUN unzip V853_NPU_Toolkits.zip \
    && cd NPU \
    && tar -xf Verisilicon_Tool_VivanteIDE_v5.7.0_CL470666_Linux_Windows_SDK_p6.4.x_dev_6.4.10_22Q1_CL473325A_20220425.tar

FROM ubuntu:20.04 as compiler

RUN apt-get update --yes \
    && apt-get install --yes \
        build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY ./Verisilicon_SW_NBInfo_1.2.4_20220420.tgz .

RUN tar -xf Verisilicon_SW_NBInfo_1.2.4_20220420.tgz \
    && cd NBGParser \
    && make STATIC_LINK=1 install \
    && cd .. \
    && make STATIC_LINK=1


FROM ubuntu:20.04 as base-cpu

FROM ${CUDA_IMAGE_NAME}:10.1-cudnn7-devel-ubuntu20.04 as base-gpu

FROM base-${TARGET_DEVICE}

RUN --mount=from=unzipper,source=/NPU,target=/tmp/NPU \
    cd /tmp/NPU \
    && ./Vivante_IDE-5.7.0_CL470666-Linux-x86_64-04-24-2022-18.55.31-plus-W-p6.4.x_dev_6.4.10_22Q1_CL473325A-Install --mode silent \
    && tar -xf Vivante_acuity_toolkit_binary_6.6.1_20220329_ubuntu20.04.tgz -C /usr/local/VeriSilicon


ENV NBINFO_PATH=/usr/local/VeriSilicon/nbinfo/bin

COPY --from=compiler /workspace/nbinfo $NBINFO_PATH/nbinfo

ENV ACUITY_TOOLS_METHOD=acuity-toolkit-binary-6.6.1
ENV ACUITY_PATH=/usr/local/VeriSilicon/$ACUITY_TOOLS_METHOD/bin
ENV VIVANTE_IED_PATH=/usr/local/VeriSilicon/VivanteIDE5.7.0
ENV VIV_SDK=$VIVANTE_IED_PATH/cmdtools
ENV PATH=$PATH:$ACUITY_PATH:$VIVANTE_IED_PATH/ide/:$NBINFO_PATH
