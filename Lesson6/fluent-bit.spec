Name:           fluent-bit
Version:        1.2.2
Release:        1%{?dist}
Summary:        by SaTaNa for otus

Group:          Apps\sys
License:        Apache 2.0
URL:            https://otus.ru

BuildRequires:  git cmake3 gtest-devel systemd-devel zlib-devel

%description
Fluent Bit is a Data Forwarder for Linux, Embedded Linux, OSX and BSD family operating systems. It's part of the Fluentd Ecosystem. Fluent Bit allows collection of information from different sources, buffering and dispatching them to different outputs such as Fluentd, Elasticsearch, Nats or any HTTP end-point within others. It's fully supported on x86_64, x86 and ARM architectures.
For more details about it capabilities and general features please visit the official documentation:
https://docs.fluentbit.io/

%prep
git clone https://github.com/fluent/fluent-bit.git 

%build
cmake3 -B fluent-bit/build/ -DFLB_ALL=on -DFLB_JEMALLOC=on -DFLB_HTTP_SERVER=on fluent-bit/
make -C fluent-bit/build/

%install
make -C fluent-bit/build/ install DESTDIR=%{buildroot}

%files
/lib/systemd/system/fluent-bit.service
/usr/local/*
