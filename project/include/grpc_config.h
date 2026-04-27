#ifndef GRPC_CONFIG_H
#define GRPC_CONFIG_H

#include <grpcpp/grpcpp.h>
#include <memory>
#include <string>

namespace ECProject {

constexpr int kGrpcMaxMessageBytes = 8 * 1024 * 1024;

inline std::shared_ptr<grpc::Channel> CreateChannelWithMaxMessageSize(
    const std::string &target) {
  grpc::ChannelArguments channel_args;
  channel_args.SetMaxReceiveMessageSize(kGrpcMaxMessageBytes);
  channel_args.SetMaxSendMessageSize(kGrpcMaxMessageBytes);
  return grpc::CreateCustomChannel(target, grpc::InsecureChannelCredentials(),
                                   channel_args);
}

inline void ConfigureServerBuilderMessageSize(grpc::ServerBuilder &builder) {
  builder.SetMaxReceiveMessageSize(kGrpcMaxMessageBytes);
  builder.SetMaxSendMessageSize(kGrpcMaxMessageBytes);
}

} // namespace ECProject

#endif // GRPC_CONFIG_H
