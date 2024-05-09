export INSTALL_ROOT=$PREFIX

sh install.sh

# Tinker with interpreter paths
if [[ "${target_platform}" == "linux-aarch64" ]]; then
  patchelf --set-interpreter $PREFIX/aarch64-conda-linux-gnu/sysroot/lib64/ld-linux-aarch64.so.1 $PREFIX/bin/sbcl
fi

mkdir -p $PREFIX/etc/conda/activate.d/
mkdir -p $PREFIX/etc/conda/deactivate.d/

cat >$PREFIX/etc/conda/activate.d/activate_sbcl.sh <<EOL
#!/bin/sh
export SBCL_HOME=\$CONDA_PREFIX/lib/sbcl
EOL

cat >$PREFIX/etc/conda/deactivate.d/deactivate_sbcl.sh <<EOL
#!/bin/sh
unset SBCL_HOME
EOL

chmod u+x $PREFIX/etc/conda/activate.d/activate_sbcl.sh
chmod u+x $PREFIX/etc/conda/deactivate.d/deactivate_sbcl.sh