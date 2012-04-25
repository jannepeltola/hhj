require 'spec_helper'

describe PositionApplication do

  context 'eligibility' do
    it 'is valid for a call if there are no rules set' do
      application = FactoryGirl.create(:kirjakerho_application)
      application.eligible?.should == true
    end
  end

  context '(when marking applicants for selection)' do

    PositionApplication.all.each do | application |
      application.selected_as.should == nil
    end

    check_all_self_references_are_nil = lambda do
      PositionApplication.all.each do |position_application|
        position_application.deputy.should == nil
        position_application.member.should == nil
      end
    end

    it 'can mark applicant as not selected' do
      application = FactoryGirl.create(:kirjakerho_application)
      application.mark_as_not_selected!
      PositionApplication.all.each do |a|
        a.selected_as.should == nil
      end
    end

    it 'can mark multiple applications according to selections' do
      applications = FactoryGirl.create_list(:kirjakerho_application, 7)

      applications[0..2].each{ |a| a.mark_as_deputy!(nil) }
      applications[3..4].each{ |a| a.mark_as_member!(nil) }
      applications[5..5].each{ |a| a.mark_as_not_selected! }


      PositionApplication.where(selected_as: :position_deputy).count.should == 3
      PositionApplication.where(selected_as: :position_member).count.should == 2
      PositionApplication.where(selected_as: nil).count.should == 2
    end

    it 'can set member for deputy and deputy for member' do
      applications = FactoryGirl.create_list(:kirjakerho_application, 2)

      applications[0].mark_as_member!(nil)
      applications[1].mark_as_deputy!(applications[0].id.to_s)

      PositionApplication.where(selected_as: :position_deputy).first.member.id.to_s.should == applications[0].id.to_s
      PositionApplication.where(selected_as: :position_member).first.deputy.id.to_s.should == applications[1].id.to_s

      applications[0].reload.mark_as_deputy!(nil)
      applications[1].reload.mark_as_member!(applications[0].id.to_s)

      PositionApplication.where(selected_as: :position_deputy).first.member.id.to_s.should == applications[1].id.to_s
      PositionApplication.where(selected_as: :position_member).first.deputy.id.to_s.should == applications[0].id.to_s
    end


    it 'clears old deputy-member relations when deputy changes' do
      applications = FactoryGirl.create_list(:kirjakerho_application, 3)

      applications[0].mark_as_member!(nil)
      applications[1].mark_as_deputy!(applications[0].id.to_s)
      applications[2].mark_as_deputy!(applications[0].id.to_s)

      PositionApplication.find(applications[0].id).deputy.id.should == applications[2].id
      PositionApplication.find(applications[0].id).member.should == nil
      PositionApplication.find(applications[1].id).member.should == nil
      PositionApplication.find(applications[1].id).deputy.should == nil
      PositionApplication.find(applications[2].id).member.id.should == applications[0].id
      PositionApplication.find(applications[2].id).deputy.should == nil
    end

    it 'can reset deputy/member' do
      applications = FactoryGirl.create_list(:kirjakerho_application, 2)

      applications[0].mark_as_deputy!(nil)
      applications[1].mark_as_member!(applications[0].id.to_s)
      applications[0].reload.mark_as_deputy!(nil)

      PositionApplication.all.each do |position_application|
        position_application.deputy.should == nil
        position_application.member.should == nil
      end
      check_all_self_references_are_nil.call
    end

    it 'resets deputy/member if unselected' do
      applications = FactoryGirl.create_list(:kirjakerho_application, 2)

      applications[0].mark_as_deputy!(nil)
      applications[1].mark_as_member!(applications[0].id.to_s)
      applications[0].reload.mark_as_not_selected!
      check_all_self_references_are_nil.call
    end
  end
end
