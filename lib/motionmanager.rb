require 'ostruct'
require './lib/math/vec3.rb'
require './lib/math/quat.rb'

class MotionManager
    def initialize()
        
    end
end

class ModelMotion
    def initialize(model)
        @model = model
        @bone_motions = Hash.new()
        @bone_frames = Hash.new()
        @last_frame = 0
    end
    
    def add_bone_motion(bones, merge_flag, frame_offset)
        if !merge_flag
            @bone_motions = Array.new()
            @bone_frames = Array.new()
        end
        
        frame_offset = frame_offset || 0
        
        bones.each do |bone|
            if @bone_motions.key?(bone.name)
                init_bone(bone)
            end
            
            frame = bone.frame + frame_offset
            @bone_motions[bone.name][frame] = bone
            @last_frame = frame if frame > @last_frame
        end
        
        @bone_motions.keys.each do |name|
            @bone_frames[name] = (@bone_frames[name] || []).concat(@bone_motions[name].keys).sort{|a, b| a <=> b}
        end
    end
    
    def init_bone(bone)
        @bone_motions[bone.name] = [OpenStruct.new({location: Vector3.new(), rotation: Quaternion.new(0, 0, 0, 1)})]
    end
end
