use_frameworks!

source 'git@gitee.com:mylDast1/MySpecRepo-kit.git'
source 'https://mirrors.tuna.tsinghua.edu.cn/git/CocoaPods/Specs.git'

def shared_pods
    pod 'CoreGPX', git: 'https://github.com/vincentneo/CoreGPX.git'
   
end

target 'OpenGpxTracker' do
    platform :ios, '13.0'
    shared_pods
    pod 'MapCache', '~> 0.10.0'
    #pod 'MapCache', git: 'https://github.com/vincentneo/MapCache.git', :branch => 'ios16-add-overlay-patch'
    
    pod 'HTMSearchKit'
end

target 'OpenGpxTracker-Watch Extension' do
    platform :watchos, '4.0'
    shared_pods
end
