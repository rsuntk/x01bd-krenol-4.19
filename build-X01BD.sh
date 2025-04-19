export PATH="$HOME/zyc-clang/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/zyc-clang/lib"
SECONDS=0
ZIPNAME="Rissu-X01BD-$(date '+%Y%m%d-%H%M').zip"
DEFCONFIG="asus/rsuntk-x01bd_defconfig"

if test -z "$(git rev-parse --show-cdup 2>/dev/null)" &&
   head=$(git rev-parse --verify HEAD 2>/dev/null); then
	ZIPNAME="${ZIPNAME::-4}-$(echo $head | cut -c1-8).zip"
fi

if ! [ -d "$HOME/zyc-clang" ]; then
echo "ZyC Clang not found! Cloning..."
wget -q  $(curl https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-14-link.txt 2>/dev/null) -O "ZyC-Clang-14.tar.gz"
mkdir ~/zyc-clang
tar -xf ZyC-Clang-14.tar.gz -C ~/zyc-clang
rm -rf ZyC-Clang-14.tar.gz
fi

export BUILD_USERNAME=rsuntk
export BUILD_HOSTNAME=nobody
export KBUILD_BUILD_USER=rsuntk
export KBUILD_BUILD_HOST=nobody

if [[ $1 = "-r" || $1 = "--regen" ]]; then
make O=out ARCH=arm64 $DEFCONFIG savedefconfig
cp out/defconfig arch/arm64/configs/$DEFCONFIG
echo -e "\nRegened defconfig succesfully!"
exit
fi

if [[ $1 = "-c" || $1 = "--clean" ]]; then
echo -e "\nClean build!"
rm -rf out
fi

MK_FLAGS="
O=out
ARCH=arm64
CC=clang
LD=ld.lld
AR=llvm-ar
AS=llvm-as
NM=llvm-nm
OBJCOPY=llvm-objcopy
OBJDUMP=llvm-objdump
STRIP=llvm-strip
CROSS_COMPILE=aarch64-linux-gnu-
CROSS_COMPILE_COMPAT=arm-linux-gnueabi-
CLANG_TRIPLE=aarch64-linux-gnu- 
"

mkdir -p out
make O=out ARCH=arm64 $DEFCONFIG

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $(echo $MK_FLAGS) Image.gz-dtb

if [ -f "out/arch/arm64/boot/Image.gz-dtb" ]; then
echo -e "\nKernel compiled succesfully! Zipping up...\n"
git clone -q https://github.com/rsuntk/AnyKernel3
cp out/arch/arm64/boot/Image.gz-dtb AnyKernel3
sed -i "s/BLOCK=.*/BLOCK=\/dev\/block\bootdevice\/by-name\/boot;/" "./AnyKernel3/anykernel.sh"
cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x '*.git*' README.md *placeholder
cd ..
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"
else
echo -e "\nCompilation failed!"
fi
